import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/face_gate.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart' show pinRouteFor;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/core/security/face_liveness.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/auth/providers/face_gate_provider.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';

enum _Stage { intro, starting, scanning, success, error }

enum _Problem { permission, permissionForever, noCamera, timeout, generic }

/// Bank-style guided face verification: instructions -> permission -> live
/// camera with an oval guide and randomized liveness challenges -> result.
/// Frames are analysed on-device by ML Kit and never stored or uploaded.
class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key, this.targetRoute});

  final String? targetRoute;

  @override
  ConsumerState<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen>
    with WidgetsBindingObserver {
  static const _scanTimeout = Duration(seconds: 60);
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final LivenessEngine _engine = LivenessEngine();
  FaceDetector? _detector;
  CameraController? _cam;
  CameraDescription? _desc;
  Timer? _timeout;

  _Stage _stage = _Stage.intro;
  _Problem _problem = _Problem.generic;
  LivenessState _live = const LivenessState(
    hint: LivenessHint.noFace,
    completed: 0,
    total: 2,
  );
  bool _busy = false;
  bool _pinAvailable = false;
  bool _supportBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Coming back from the PIN screen without unlocking cancels the detour.
      ref.read(faceGateProvider.notifier).setPinFallback(false);
      _checkPin();
    });
  }

  Future<void> _checkPin() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final v = ref.read(verificationServiceProvider);
    final ok =
        await v.accessCodeOwnerUid() == uid && await v.accessCodeExists();
    if (mounted) setState(() => _pinAvailable = ok);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeout?.cancel();
    _releaseCamera();
    _detector?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        (_stage == _Stage.scanning || _stage == _Stage.starting)) {
      _releaseCamera();
      _timeout?.cancel();
      if (mounted) setState(() => _stage = _Stage.intro);
    }
  }

  // ---- camera lifecycle --------------------------------------------------

  Future<void> _start() async {
    setState(() => _stage = _Stage.starting);
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        return _fail(
          status.isPermanentlyDenied || status.isRestricted
              ? _Problem.permissionForever
              : _Problem.permission,
        );
      }
      final cams = await availableCameras();
      final front = cams
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      if (front.isEmpty) return _fail(_Problem.noCamera);
      _desc = front.first;

      final cam = CameraController(
        _desc!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      _cam = cam;
      _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      _engine.reset();
      _live = LivenessState(
        hint: LivenessHint.noFace,
        completed: 0,
        total: _engine.challengeCount,
      );
      await cam.startImageStream(_onFrame);
      _timeout?.cancel();
      _timeout = Timer(_scanTimeout, () => _fail(_Problem.timeout));
      if (mounted) setState(() => _stage = _Stage.scanning);
    } on CameraException catch (e) {
      _fail(
        e.code.contains('AccessDenied')
            ? _Problem.permission
            : _Problem.generic,
      );
    } catch (_) {
      _fail(_Problem.generic);
    }
  }

  Future<void> _releaseCamera() async {
    final cam = _cam;
    _cam = null;
    if (cam == null) return;
    try {
      if (cam.value.isStreamingImages) await cam.stopImageStream();
    } catch (_) {}
    try {
      await cam.dispose();
    } catch (_) {}
  }

  void _fail(_Problem p) {
    _timeout?.cancel();
    _releaseCamera();
    if (!mounted) return;
    setState(() {
      _problem = p;
      _stage = _Stage.error;
    });
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _stage != _Stage.scanning) return;
    _busy = true;
    try {
      final conv = _toInputImage(image);
      final detector = _detector;
      if (conv == null || detector == null) return;
      final faces = await detector.processImage(conv.$1);
      if (!mounted || _stage != _Stage.scanning) return;
      final next = _engine.update(_sampleOf(faces, conv.$2));
      if (next.completed > _live.completed) HapticFeedback.lightImpact();
      setState(() => _live = next);
      if (next.passed) await _finish();
    } catch (_) {
      // A single bad frame must not kill the scan; the timeout still applies.
    } finally {
      _busy = false;
    }
  }

  FaceSample _sampleOf(List<Face> faces, Size frame) {
    if (faces.isEmpty) return const FaceSample.none();
    final f = faces.first;
    final box = f.boundingBox;
    return FaceSample(
      faceCount: faces.length,
      centerX: box.center.dx / frame.width,
      centerY: box.center.dy / frame.height,
      widthRatio: box.width / frame.width,
      yaw: f.headEulerAngleY,
      leftEyeOpen: f.leftEyeOpenProbability,
      rightEyeOpen: f.rightEyeOpenProbability,
      smile: f.smilingProbability,
    );
  }

  /// Returns the ML Kit input plus the frame size *after* rotation.
  (InputImage, Size)? _toInputImage(CameraImage image) {
    final cam = _cam, desc = _desc;
    if (cam == null || desc == null) return null;
    final sensor = desc.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensor);
    } else {
      var comp = _orientations[cam.value.deviceOrientation];
      if (comp == null) return null;
      comp = desc.lensDirection == CameraLensDirection.front
          ? (sensor + comp) % 360
          : (sensor - comp + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(comp);
    }
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888) ||
        image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    final raw = Size(image.width.toDouble(), image.height.toDouble());
    final swap =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    return (
      InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: raw,
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      ),
      swap ? Size(raw.height, raw.width) : raw,
    );
  }

  Future<void> _finish() async {
    _timeout?.cancel();
    await _releaseCamera();
    if (!mounted) return;
    setState(() => _stage = _Stage.success);
    HapticFeedback.mediumImpact();
    await ref
        .read(faceGateProvider.notifier)
        .markVerified(method: 'liveness', challenges: _live.total);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    // The router also redirects away once the gate opens; go() is idempotent.
    if (mounted) {
      context.go(resumableFaceTarget(widget.targetRoute) ?? Routes.home);
    }
  }

  // ---- actions -----------------------------------------------------------

  void _cancel() {
    _timeout?.cancel();
    _releaseCamera();
    // Dismiss the one-shot post-PIN challenge so home does not bounce straight
    // back here; protected features still ask again.
    ref.read(faceGateProvider.notifier).dismissPending();
    context.go(Routes.home);
  }

  void _usePin() {
    ref.read(faceGateProvider.notifier).setPinFallback(true);
    context.go(
      pinRouteFor(
        location: resumableFaceTarget(widget.targetRoute) ?? Routes.home,
      ),
    );
  }

  Future<void> _contactSupport() async {
    if (_supportBusy) return;
    setState(() => _supportBusy = true);
    final l = AppLocalizations.of(context);
    try {
      await ref.read(faceGateProvider.notifier).requestManualReview();
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          icon: Icons.support_agent_rounded,
          message: l.faceSupportSent,
        );
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.faceSupportFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _supportBusy = false);
    }
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final cam = _cam;
    final showCamera =
        cam != null && cam.value.isInitialized && _stage == _Stage.scanning;
    final ringColor = switch (_stage) {
      _Stage.success => Colors.green,
      _Stage.error => cs.error,
      _Stage.scanning =>
        _live.hint == LivenessHint.challenge ||
                _live.hint == LivenessHint.holdStill
            ? cs.primary
            : cs.onSurface.withValues(alpha: .7),
      _ => cs.onSurface.withValues(alpha: .4),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (showCamera) _preview(cam),
            CustomPaint(
              painter: _OvalGuidePainter(
                dim: cs.surface.withValues(alpha: showCamera ? .72 : 1),
                ring: ringColor,
                centerY: .42,
              ),
              child: Align(
                alignment: const Alignment(0, -.16),
                child: _stage == _Stage.scanning
                    ? null
                    : Icon(
                        _stage == _Stage.success
                            ? Icons.check_circle_rounded
                            : _stage == _Stage.error
                            ? Icons.no_photography_rounded
                            : Icons.face_6_rounded,
                        size: 96,
                        color: ringColor,
                      ),
              ),
            ),
            Positioned(top: 0, left: 16, right: 16, child: _topBar(l, cs)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: _GlassPanel(child: _bottom(l, cs)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(CameraController c) {
    final s = c.value.previewSize!;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: s.height,
          height: s.width,
          child: CameraPreview(c),
        ),
      ),
    );
  }

  Widget _topBar(AppLocalizations l, ColorScheme cs) {
    return _GlassPanel(
      floating: false,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.faceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l.cancel,
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottom(AppLocalizations l, ColorScheme cs) {
    final t = Theme.of(context).textTheme;
    switch (_stage) {
      case _Stage.intro:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.faceIntroTitle, style: t.titleLarge),
            const SizedBox(height: 6),
            Text(l.faceIntroBody, style: t.bodyMedium),
            const SizedBox(height: 14),
            _Tip(Icons.center_focus_strong_rounded, l.faceTipCenter),
            _Tip(Icons.light_mode_rounded, l.faceTipLight),
            _Tip(Icons.masks_rounded, l.faceTipObstruct),
            _Tip(Icons.pan_tool_alt_rounded, l.faceTipStill),
            const SizedBox(height: 14),
            FilledButton(onPressed: _start, child: Text(l.faceStart)),
            ..._fallbacks(l),
          ],
        );
      case _Stage.starting:
        return const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        );
      case _Stage.scanning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _hintText(l),
                key: ValueKey(_hintText(l)),
                textAlign: TextAlign.center,
                style: t.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _live.total; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i < _live.completed ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: i < _live.completed
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: .25),
                    ),
                  ),
              ],
            ),
          ],
        );
      case _Stage.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.faceSuccessTitle, style: t.titleLarge),
            const SizedBox(height: 6),
            Text(
              l.faceSuccessBody,
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
          ],
        );
      case _Stage.error:
        final (title, body) = switch (_problem) {
          _Problem.permission || _Problem.permissionForever => (
            l.faceErrPermissionTitle,
            l.faceErrPermissionBody,
          ),
          _Problem.noCamera => (l.faceErrNoCameraTitle, l.faceErrNoCameraBody),
          _Problem.timeout => (l.faceErrTimeoutTitle, l.faceErrTimeoutBody),
          _Problem.generic => (l.faceErrGenericTitle, l.faceErrGenericBody),
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleLarge),
            const SizedBox(height: 6),
            Text(body, style: t.bodyMedium),
            const SizedBox(height: 14),
            if (_problem == _Problem.permissionForever)
              FilledButton(
                onPressed: openAppSettings,
                child: Text(l.faceOpenSettings),
              )
            else if (_problem != _Problem.noCamera)
              FilledButton(onPressed: _start, child: Text(l.retry)),
            ..._fallbacks(l),
          ],
        );
    }
  }

  List<Widget> _fallbacks(AppLocalizations l) => [
    if (_pinAvailable)
      TextButton(onPressed: _usePin, child: Text(l.faceUsePin)),
    TextButton(
      onPressed: _supportBusy ? null : _contactSupport,
      child: Text(l.faceContactSupport),
    ),
  ];

  String _hintText(AppLocalizations l) {
    switch (_live.hint) {
      case LivenessHint.noFace:
        return l.faceHintNoFace;
      case LivenessHint.multipleFaces:
        return l.faceHintMultiple;
      case LivenessHint.moveCloser:
        return l.faceHintCloser;
      case LivenessHint.moveFarther:
        return l.faceHintFarther;
      case LivenessHint.centerFace:
        return l.faceHintCenter;
      case LivenessHint.holdStill:
        return l.faceHintHold;
      case LivenessHint.passed:
        return l.faceSuccessTitle;
      case LivenessHint.challenge:
        return switch (_live.challenge) {
          LivenessChallenge.blink => l.faceChallengeBlink,
          LivenessChallenge.smile => l.faceChallengeSmile,
          LivenessChallenge.turnHead => l.faceChallengeTurn,
          null => l.faceHintHold,
        };
    }
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Frosted panel (backdrop blur). [floating] = free-standing rounded card;
/// otherwise only the bottom corners are rounded (docked to the top edge).
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.floating = true});

  final Widget child;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: floating
          ? const BorderRadius.all(Radius.circular(24))
          : const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              cs.primary.withValues(alpha: 0.04),
              cs.surface.withValues(alpha: .35),
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: floating
                ? const EdgeInsets.all(20)
                : const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside an oval cut-out and strokes the oval.
class _OvalGuidePainter extends CustomPainter {
  _OvalGuidePainter({
    required this.dim,
    required this.ring,
    required this.centerY,
  });

  final Color dim;
  final Color ring;
  final double centerY;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * .72;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * centerY),
      width: w,
      height: w * 1.32,
    );
    final screen = Path()..addRect(Offset.zero & size);
    final hole = Path()..addOval(oval);
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, hole),
      Paint()..color = dim,
    );
    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_OvalGuidePainter o) =>
      o.dim != dim || o.ring != ring || o.centerY != centerY;
}
