import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

// ─────────────────────────────────────────────────────────────
// Max canvas size on wide/desktop screens to prevent overflow
// and keep the pixel-scan work bounded.
// ─────────────────────────────────────────────────────────────
const double _kMaxDimension = 800.0;

// Step sizes used by the adaptive quality system.
// 0.5 = crisp; 1.0 = good; 2.0 = low-end fallback.
const double _kStepHigh = 0.5;
const double _kStepMid = 1.0;
const double _kStepLow = 1.5;

// FPS thresholds for auto-degradation / recovery.
const double _kFpsDropThreshold = 15.0; // degrade when below this
const double _kFpsRecoverThreshold = 50.0; // recover when above this

// How many frames to sample before making a quality decision.
const int _kFpsSampleWindow = 20;

class LavaLampMetaBalls extends StatefulWidget {
  const LavaLampMetaBalls({super.key});

  @override
  State<LavaLampMetaBalls> createState() => _LavaLampMetaBallsState();
}

class _LavaLampMetaBallsState extends State<LavaLampMetaBalls>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  // ── Coordinate system ─────────────────────────────────────
  // Positions are stored as fractions of the canvas:
  //   xRel ∈ [0, 1]  maps to  [0, canvasW] pixels
  //   yRel ∈ [0, 1]  maps to  [0, canvasH] pixels
  // Center of canvas = (0.5, 0.5).
  // Radii are stored as a fraction of the SHORTER side so balls
  // look the same regardless of aspect ratio.
  Offset p1Relative = const Offset(0.35, 0.5);
  Offset p2Relative = const Offset(0.6, 0.45);
  final double _r1Ratio = 0.09;
  final double _r2Ratio = 0.16;

  // Last known canvas size — updated every build, used by collision code.
  double _canvasW = 1;
  double _canvasH = 1;

  final Random random = Random();
  double r1Multiplier = 1.0;
  double r2Multiplier = 1.0;
  double proximityFactor = 0.0;
  final double dampingFactor = 0.95;

  // --- Mode Switching State ---
  bool _usePhysicsMode = false;
  late Offset base1Relative, base2Relative;
  Offset v1 = Offset.zero;
  Offset v2 = Offset.zero;

  // ── Adaptive quality ──────────────────────────────────────
  double _step = kIsWeb ? _kStepMid : _kStepHigh;
  final List<double> _frameTimes = [];
  Duration? _lastFrameTime;
  int _qualityCooldown = 0;
  static const int _cooldownFrames = 60;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(_tick);

    base1Relative = p1Relative;
    base2Relative = p2Relative;

    controller.repeat();
  }

  void _tick() {
    _measureFps();
    setState(_update);
  }

  // ── FPS measurement & adaptive step ──────────────────────
  void _measureFps() {
    final now = controller.lastElapsedDuration;
    if (now == null) return;

    if (_lastFrameTime != null) {
      final dtMs = (now - _lastFrameTime!).inMicroseconds / 1000.0;
      if (dtMs > 0) _frameTimes.add(dtMs);
      if (_frameTimes.length > _kFpsSampleWindow) {
        _frameTimes.removeAt(0);
      }
    }
    _lastFrameTime = now;

    if (_qualityCooldown > 0) {
      _qualityCooldown--;
      return;
    }

    if (_frameTimes.length < _kFpsSampleWindow) return;

    final avgMs = _frameTimes.fold(0.0, (a, b) => a + b) / _frameTimes.length;
    final fps = 1000.0 / avgMs;

    if (fps < _kFpsDropThreshold && _step < _kStepLow) {
      _step = (_step == _kStepHigh) ? _kStepMid : _kStepLow;
      _frameTimes.clear();
      _qualityCooldown = _cooldownFrames;
    } else if (fps > _kFpsRecoverThreshold && _step > _kStepHigh) {
      if (!kIsWeb) {
        _step = (_step == _kStepLow) ? _kStepMid : _kStepHigh;
        _frameTimes.clear();
        _qualityCooldown = _cooldownFrames;
      }
    }
  }

  void _handleTap() {
    setState(() {
      _usePhysicsMode = !_usePhysicsMode;
      if (_usePhysicsMode) {
        v1 = Offset(random.nextDouble() * 0.01 - 0.005,
            random.nextDouble() * 0.01 - 0.005);
        v2 = Offset(random.nextDouble() * 0.01 - 0.005,
            random.nextDouble() * 0.01 - 0.005);
      } else {
        base1Relative = p1Relative;
        base2Relative = p2Relative;
        v1 = Offset.zero;
        v2 = Offset.zero;
      }
    });
  }

  void _update() {
    if (_usePhysicsMode) {
      _updatePhysicsMode();
    } else {
      _updateWaveMode();
    }

    final distance = (p1Relative - p2Relative).distance;
    final maxDistForInteraction = (_r1Ratio + _r2Ratio) * 1.5;
    proximityFactor = (1 - (distance / maxDistForInteraction)).clamp(0.0, 1.0);

    final t = controller.lastElapsedDuration!.inMilliseconds / 1000.0;
    r1Multiplier = 1.0 + sin(t * 0.6) * 0.015;
    r2Multiplier = 1.0 + cos(t * 0.5) * 0.02;
  }

  void _updateWaveMode() {
    final t = controller.lastElapsedDuration!.inMilliseconds / 1000.0;

    const double ampX1 = 0.07, ampY1 = 0.05;
    const double ampX2 = 0.06, ampY2 = 0.045;

    p1Relative = Offset(
      base1Relative.dx +
          sin(t * 0.35) * ampX1 +
          sin(t * 0.9 + 2.1) * ampX1 * 0.3,
      base1Relative.dy +
          cos(t * 0.27 + 1.3) * ampY1 +
          sin(t * 0.55 + 0.4) * ampY1 * 0.4,
    );

    p2Relative = Offset(
      base2Relative.dx +
          sin(t * 0.42 + 0.8) * ampX2 +
          cos(t * 0.8 + 1.7) * ampX2 * 0.25,
      base2Relative.dy +
          cos(t * 0.31 + 2.4) * ampY2 +
          sin(t * 0.6 + 1.2) * ampY2 * 0.35,
    );
  }

  void _updatePhysicsMode() {
    p1Relative += v1;
    p2Relative += v2;
    _handleBallCollision();
    _handleWallCollisions();
  }

  // ── Ball–ball collision ───────────────────────────────────
  // Distances in relative space are non-uniform when the canvas
  // is rectangular, so convert to pixels for the geometry, then
  // convert the resolution back.
  void _handleBallCollision() {
    final shortSide = min(_canvasW, _canvasH);
    final r1Px = (_r1Ratio - 0.004 * r1Multiplier) * shortSide;
    final r2Px = (_r2Ratio - 0.04 * r2Multiplier) * shortSide;
    final minDistPx = r1Px + r2Px;

    final dx = (p1Relative.dx - p2Relative.dx) * _canvasW;
    final dy = (p1Relative.dy - p2Relative.dy) * _canvasH;
    final distPx = sqrt(dx * dx + dy * dy);

    if (distPx < minDistPx && distPx > 0) {
      final overlap = minDistPx - distPx;
      final normalX = dx / distPx;
      final normalY = dy / distPx;

      // Push apart in pixel space, convert back to relative.
      p1Relative = Offset(
        p1Relative.dx + normalX * overlap / 2 / _canvasW,
        p1Relative.dy + normalY * overlap / 2 / _canvasH,
      );
      p2Relative = Offset(
        p2Relative.dx - normalX * overlap / 2 / _canvasW,
        p2Relative.dy - normalY * overlap / 2 / _canvasH,
      );

      // Velocities are in relative units; scale to pixel-space for dot product.
      final v1px = Offset(v1.dx * _canvasW, v1.dy * _canvasH);
      final v2px = Offset(v2.dx * _canvasW, v2.dy * _canvasH);
      final dot = (v1px.dx - v2px.dx) * normalX + (v1px.dy - v2px.dy) * normalY;

      v1 = Offset(
        v1.dx - dot * normalX * dampingFactor / _canvasW,
        v1.dy - dot * normalY * dampingFactor / _canvasH,
      );
      v2 = Offset(
        v2.dx + dot * normalX * dampingFactor / _canvasW,
        v2.dy + dot * normalY * dampingFactor / _canvasH,
      );
    }
  }

  // ── Wall collisions ───────────────────────────────────────
  // Bounds are [0..1] on each axis independently.
  // Radius is expressed as a fraction of the shorter side, then
  // converted to the matching axis fraction for clamping.
  void _handleWallCollisions() {
    final shortSide = min(_canvasW, _canvasH);
    final r1Px = (_r1Ratio + (0.09) * r1Multiplier) * shortSide;
    final r2Px = (_r2Ratio + (0.009) * r2Multiplier) * shortSide;

    // Fraction of each axis that the ball radius occupies.
    final r1x = r1Px / _canvasW;
    final r1y = r1Px / _canvasH;
    final r2x = r2Px / _canvasW;
    final r2y = r2Px / _canvasH;

    if (p1Relative.dx <= r1x || p1Relative.dx >= 1.0 - r1x) {
      v1 = Offset(-v1.dx * dampingFactor, v1.dy);
      p1Relative = Offset(p1Relative.dx.clamp(r1x, 1.0 - r1x), p1Relative.dy);
    }
    if (p1Relative.dy <= r1y || p1Relative.dy >= 1.0 - r1y) {
      v1 = Offset(v1.dx, -v1.dy * dampingFactor);
      p1Relative = Offset(p1Relative.dx, p1Relative.dy.clamp(r1y, 1.0 - r1y));
    }

    if (p2Relative.dx <= r2x || p2Relative.dx >= 1.0 - r2x) {
      v2 = Offset(-v2.dx * dampingFactor, v2.dy);
      p2Relative = Offset(p2Relative.dx.clamp(r2x, 1.0 - r2x), p2Relative.dy);
    }
    if (p2Relative.dy <= r2y || p2Relative.dy >= 1.0 - r2y) {
      v2 = Offset(v2.dx, -v2.dy * dampingFactor);
      p2Relative = Offset(p2Relative.dx, p2Relative.dy.clamp(r2y, 1.0 - r2y));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ── Canvas size ───────────────────────────────────────
        // Fill all available width. Height: use available if finite
        // (e.g. when the parent gives a real constraint), otherwise
        // fall back to a 16:9-ish proportion of the width.
        final canvasW = min(constraints.maxWidth, _kMaxDimension);
        final canvasH = constraints.maxHeight.isFinite
            ? min(constraints.maxHeight, _kMaxDimension)
            : canvasW * .9;

        // Stash for collision math (no setState — only read during _update).
        _canvasW = canvasW;
        _canvasH = canvasH;

        final shortSide = min(canvasW, canvasH) - 120;

        // Convert from [0..1] relative coords to pixel positions.
        final p1 = Offset(p1Relative.dx * canvasW, p1Relative.dy * canvasH);
        final p2 = Offset(p2Relative.dx * canvasW, p2Relative.dy * canvasH);
        final r1 = shortSide * _r1Ratio * r1Multiplier;
        final r2 = shortSide * _r2Ratio * r2Multiplier;

        final gradientColor = ColorTween(
          begin: Theme.of(context).colorScheme.primary,
          end: Theme.of(context).colorScheme.tertiary,
        ).lerp(proximityFactor)!;

        return GestureDetector(
          onTap: _handleTap,
          child: SizedBox(
            width: canvasW,
            height: canvasH,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MetaPainter(
                  p1: p1,
                  p2: p2,
                  r1: r1,
                  r2: r2,
                  step: _step,
                  gradient: LinearGradient(
                    colors: [gradientColor, gradientColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  theme: Theme.of(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────

class MetaPainter extends CustomPainter {
  final Offset p1, p2;
  final double r1, r2;
  final double step; // ← was hardcoded to 0.5; now passed in
  final Gradient gradient;
  final ThemeData theme;

  MetaPainter({
    required this.p1,
    required this.p2,
    required this.r1,
    required this.r2,
    required this.step,
    required this.gradient,
    required this.theme,
  });

  late final double _r1Sq = r1 * r1;
  late final double _r2Sq = r2 * r2;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = gradient.createShader(Offset.zero & size);

    final path = _buildMetaballPath(size, step: step);
    final metaPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = shader;

    canvas.drawPath(path, metaPaint);

    final ballPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = theme.colorScheme.surface;

    canvas.drawCircle(p1, r1, ballPaint);
    canvas.drawCircle(p2, r2, ballPaint);
  }

  double _fieldValue(double x, double y) {
    final dx1 = x - p1.dx;
    final dy1 = y - p1.dy;
    final dx2 = x - p2.dx;
    final dy2 = y - p2.dy;

    double d1Sq = dx1 * dx1 + dy1 * dy1;
    double d2Sq = dx2 * dx2 + dy2 * dy2;

    if (d1Sq < 0.1) d1Sq = 0.1;
    if (d2Sq < 0.1) d2Sq = 0.1;

    return _r1Sq / d1Sq + _r2Sq / d2Sq;
  }

  Path _buildMetaballPath(Size size, {required double step}) {
    const threshold = 0.6;
    final Path path = Path();

    final int xSteps = (size.width / step).ceil();
    final int ySteps = (size.height / step).ceil();

    for (int y = 0; y < ySteps; y++) {
      final double yPos = y * step;
      bool drawing = false;

      for (int x = 0; x < xSteps; x++) {
        final double xPos = x * step;
        final double v = _fieldValue(xPos, yPos);
        final bool inside = v >= threshold;

        if (inside && !drawing) {
          path.moveTo(xPos, yPos);
          drawing = true;
        } else if (inside && drawing) {
          path.lineTo(xPos, yPos);
        } else if (!inside && drawing) {
          drawing = false;
        }
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant MetaPainter old) =>
      old.p1 != p1 ||
      old.p2 != p2 ||
      old.r1 != r1 ||
      old.r2 != r2 ||
      old.step != step;
}
