import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart';
import 'package:tarlan_bank/core/security/pin_lockout.dart';
import 'package:tarlan_bank/core/security/pin_lockout_store.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/auth/providers/pin_gate_provider.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/verification_dialog.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/user_settings.dart';

import '../shared/widgets.dart';

/// Access-code gate. All dependencies arrive through Riverpod providers and
/// navigation uses go_router. The router supplies [createCode], [resetCode]
/// and [targetRoute] as query parameters; all are safely defaulted.
class CodeEnteringScreen extends ConsumerStatefulWidget {
  const CodeEnteringScreen({
    super.key,
    this.createCode = false,
    this.resetCode = false,
    this.targetRoute,
  });

  final bool createCode;
  final bool resetCode;
  final String? targetRoute;

  @override
  ConsumerState<CodeEnteringScreen> createState() => CodeEnteringScreenState();
}

class CodeEnteringScreenState extends ConsumerState<CodeEnteringScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _codeFocusNode = FocusNode();
  final LocalAuthentication _auth = LocalAuthentication();

  /// Horizontal shake is driven straight off the controller's linear 0..1
  /// value; a Curve subclass cannot be used because CurvedAnimation asserts
  /// that transform(1) is near 1, while a shake must end at rest (0).
  late final AnimationController _shakeController;
  final PinLockout _lockout = PinLockout();
  Timer? _lockoutTick;
  Duration _lockoutRemaining = Duration.zero;

  final int _codeLength = 4;
  String _enteredCode = '';
  int creationStage = 0;
  String createdCode = '';
  bool isCreatingCode = false;
  bool _biometricsEnabled = false;
  PinLockoutStore? _lockoutStore;
  bool _lockoutReady = false;

  /// Keypad stays inert until the persisted streak has been restored.
  bool get _inputBlocked => !_lockoutReady || _lockout.isLocked;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _init();
  }

  Future<void> _init() async {
    final store = ref.read(secureStoreProvider);
    await store.loadSettings();
    // Restore before the first interactive frame so a restart during a
    // lockout cannot reset the countdown or the failure streak.
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      _lockoutStore = PinLockoutStore(store, uid);
      await _lockoutStore!.restore(_lockout);
    }
    final verification = ref.read(verificationServiceProvider);
    var creating = widget.createCode;
    if (!creating) creating = !(await verification.accessCodeExists());
    if (!mounted) return;
    setState(() {
      isCreatingCode = creating;
      _biometricsEnabled = store.currentSettings?.useBiometrics == true;
      _lockoutReady = true;
      _lockoutRemaining = _lockout.remaining;
    });
    if (_lockoutRemaining > Duration.zero) _startLockoutTick();
    if (widget.resetCode && !isCreatingCode) {
      // Deep link /codeEntering?mode=reset: open the old server's 6-digit
      // email confirmation flow once the first frame is mounted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestReset(_currentEmail());
      });
    } else if (_biometricsEnabled && !isCreatingCode && !_lockout.isLocked) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _authenticateWithBiometrics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final profile = ref.watch(userProfileProvider).value;
    final authUser = ref.watch(currentUserProvider);
    final fullName = profile?.fullName ?? '';
    final email = profile?.email ?? authUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24, top: 12.0),
          child: isLandscape
              ? _buildLandscapeLayout(theme, size, fullName, email)
              : _buildPortraitLayout(theme, size, fullName, email),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    ThemeData theme,
    Size size,
    String fullName,
    String email,
  ) {
    return Column(
      children: [
        _buildBackButton(theme),
        const SizedBox(height: 12),
        SizedBox(
          width: size.width / 2,
          child: CustomCard(
            child: Center(child: buildUserCard(fullName, theme, size)),
          ),
        ),
        const SizedBox(height: 24),
        _buildAccessCodeLabel(theme),
        const SizedBox(height: 16),
        _buildCodeIndicators(theme),
        const SizedBox(height: 24),
        Expanded(child: _buildNumPad(theme, size)),
        _buildForgotCodeButton(theme, email),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    ThemeData theme,
    Size size,
    String fullName,
    String email,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            spacing: 24,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildBackButton(theme),
              SizedBox(
                width: size.width / 4,
                child: CustomCard(
                  child: Center(child: buildUserCard(fullName, theme, size)),
                ),
              ),
              _buildForgotCodeButton(theme, email),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildAccessCodeLabel(theme),
              SizedBox(height: size.height * 0.02),
              _buildCodeIndicators(theme),
              SizedBox(height: size.height * 0.02),
              Expanded(child: _buildNumPad(theme, size)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return Align(
      alignment: Alignment.topLeft,
      child: fakeHero(
        tag: 'ic_back',
        child: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/ic_back.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.menu);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAccessCodeLabel(ThemeData theme) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        isCreatingCode
            ? (creationStage == 0 ? l.auCodeCreateTitle : l.auCodeRepeatTitle)
            : l.auCodeEnterTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.outline,
          fontSize: 12,
          fontFamily: 'OpenSans',
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  /// Fixed-height slot: dots swap to the countdown without moving the keypad
  /// or the Forgot-code button.
  Widget _buildCodeIndicators(ThemeData theme) {
    if (!_lockoutReady) return const SizedBox(height: 40);
    return SizedBox(
      height: 40,
      child: Center(
        child: _lockout.isLocked
            ? _buildLockoutTimer(theme)
            : AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeOffset(_shakeController.value), 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _codeLength,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index < _enteredCode.length
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                        color: index < _enteredCode.length
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLockoutTimer(ThemeData theme) {
    final remaining = _lockoutRemaining;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final time = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
        : '$minutes:$seconds';
    final l = AppLocalizations.of(context);
    return Text(
      l.auCodeLocked(time),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildNumPad(ThemeData theme, Size size) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxAvailableHeight = constraints.maxHeight;
        final double maxAvailableWidth = constraints.maxWidth;

        const int crossAxisCount = 3;
        const int mainAxisCount = 4;
        const double spacing = 12.0;

        final double totalSpacingHeight = (mainAxisCount - 1) * spacing;
        final double buttonHeight =
            (maxAvailableHeight - totalSpacingHeight) / mainAxisCount;

        final double desiredButtonWidth = buttonHeight;
        final double requiredTotalWidth =
            (crossAxisCount * desiredButtonWidth) +
            ((crossAxisCount - 1) * spacing);
        if (requiredTotalWidth > maxAvailableWidth) {
          final double totalSpacingWidth = (crossAxisCount - 1) * spacing;
          final double buttonWidth =
              (maxAvailableWidth - totalSpacingWidth) / crossAxisCount;
          final double newButtonHeight = buttonWidth;
          final double effectiveAspectRatio = buttonWidth / newButtonHeight;
          final double effectiveHeight =
              (mainAxisCount * newButtonHeight) + totalSpacingHeight;

          return SizedBox(
            width: maxAvailableWidth,
            height: effectiveHeight,
            child: GridView.count(
              childAspectRatio: effectiveAspectRatio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              children: [
                for (var i = 1; i <= 9; i++)
                  _buildNumericButton(i.toString(), theme),
                _buildBiometricButton(theme),
                _buildNumericButton('0', theme),
                _buildDeleteButton(theme),
              ],
            ),
          );
        }

        return SizedBox(
          width: requiredTotalWidth.clamp(50, 275),
          height: maxAvailableHeight,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.0,
            children: [
              for (var i = 1; i <= 9; i++)
                _buildNumericButton(i.toString(), theme),
              _buildBiometricButton(theme),
              _buildNumericButton('0', theme),
              _buildDeleteButton(theme),
            ],
          ),
        );
      },
    );
  }

  String _currentEmail() {
    final profile = ref.read(userProfileProvider).value?.email;
    return profile ?? ref.read(currentUserProvider)?.email ?? '';
  }

  /// Forgotten-PIN recovery: sends a 6-digit code through the old
  /// server (/auth/send-verification-code -> /auth/verify-code) and
  /// switches to creation only after that code is confirmed.
  Future<void> _requestReset(String email) async {
    if (email.trim().isEmpty) {
      final l = AppLocalizations.of(context);
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auEmailConfirmationRequired,
        );
      }
      return;
    }
    final verified = await showEmailConfirmationDialog(
      email: email,
      context: context,
    );
    if (!verified || !mounted) return;
    _lockout.reset();
    await _lockoutStore?.clear();
    _lockoutTick?.cancel();
    _lockoutTick = null;
    _lockoutRemaining = Duration.zero;
    ref.read(pinGateProvider.notifier).relock();
    setState(() {
      _enteredCode = '';
      createdCode = '';
      isCreatingCode = true;
      creationStage = 0;
    });
  }

  Widget _buildForgotCodeButton(ThemeData theme, String email) {
    final l = AppLocalizations.of(context);
    final isDisabled = isCreatingCode && creationStage == 0;

    return ElevatedButton(
      style: theme.elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return theme.colorScheme.surfaceContainerHighest;
          }
          return theme.colorScheme.primary;
        }),
      ),
      onPressed: isDisabled
          ? null
          : !isCreatingCode
          ? () => _requestReset(email)
          : creationStage == 1
          ? () {
              setState(() {
                _enteredCode = '';
                createdCode = '';
                creationStage = 0;
              });
            }
          : () {},
      child: Text(
        isCreatingCode ? l.auCodeResetButton : l.auCodeForgotButton,
        style: theme.textTheme.titleSmall?.copyWith(
          color: isDisabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
              : theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildNumericButton(String value, ThemeData theme) {
    final locked = _inputBlocked;
    BorderRadius borderRadius = BorderRadius.circular(100);
    return Container(
      decoration: BoxDecoration(
        color: locked
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: borderRadius,
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          onTap: locked
              ? null
              : () {
                  if (_enteredCode.length < _codeLength) {
                    setState(() => _enteredCode += value);
                    _handleCodeEntry();
                  }
                },
          child: Center(
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: locked
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(ThemeData theme) {
    BorderRadius borderRadius = BorderRadius.circular(100);
    return (!isCreatingCode && _biometricsEnabled && !_inputBlocked)
        ? Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: borderRadius,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: borderRadius,
                splashFactory: InkRipple.splashFactory,
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                highlightColor: theme.colorScheme.primary.withValues(
                  alpha: 0.04,
                ),
                onTap: _authenticateWithBiometrics,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      // SvgPicture.asset('assets/icons/ic_biometry.svg',
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildDeleteButton(ThemeData theme) {
    final locked = _inputBlocked;
    BorderRadius borderRadius = BorderRadius.circular(100);
    return Container(
      decoration: BoxDecoration(
        color: locked
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: borderRadius,
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          onTap: locked
              ? null
              : () {
                  if (_enteredCode.isNotEmpty) {
                    setState(() {
                      _enteredCode = _enteredCode.substring(
                        0,
                        _enteredCode.length - 1,
                      );
                    });
                  }
                },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/icons/ic_clear.svg',
                width: 32,
                height: 32,
                colorFilter: ColorFilter.mode(
                  locked
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setUseBiometrics(bool value) async {
    final store = ref.read(secureStoreProvider);
    final current = await store.loadSettings() ?? UserSettings.defaults();
    await store.saveSettings(current.copyWith(useBiometrics: value));
    if (mounted) setState(() => _biometricsEnabled = value);
  }

  Future<void> _showBiometricDialog() async {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.auBiometricAuthTitle, style: theme.textTheme.titleLarge),
        content: Text(l.auBiometricAuthBody, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: theme.textButtonTheme.style,
            child: Text(l.auNo),
          ),
          TextButton(
            onPressed: () async {
              await _setUseBiometrics(true);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            style: theme.textButtonTheme.style,
            child: Text(l.auYes),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    // Biometrics must not bypass an active lockout (including the cold-start
    // auto-prompt).
    if (_inputBlocked) return;
    final l = AppLocalizations.of(context);
    var authenticated = false;
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        if (!_biometricsEnabled) await _showBiometricDialog();

        if (_biometricsEnabled) {
          authenticated = await _auth.authenticate(
            localizedReason: l.auBiometricSignInReason,
            biometricOnly: true,
            sensitiveTransaction: true,
            authMessages: <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: l.auBiometricSignInTitle,
                cancelButton: l.cancel,
                signInHint: ' ',
              ),
              IOSAuthMessages(
                localizedFallbackTitle: l.auBiometricFallbackTitle,
                cancelButton: l.cancel,
              ),
            ],
          );
        }
      } else if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.auMessageTitle,
          message: l.auBiometricNotSupported,
        );
      }
    } catch (e) {
      if (mounted &&
          e is LocalAuthException &&
          e.code != LocalAuthExceptionCode.userCanceled) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auBiometricUnavailable,
        );
      }
    }

    if (authenticated) {
      await _onAuthenticated();
    } else {
      ref.read(authStateServiceProvider).setIsLoggedIn(false);
    }
  }

  Future<void> _onAuthenticated({bool created = false}) async {
    _lockout.reset();
    await _lockoutStore?.clear();
    _lockoutTick?.cancel();
    _lockoutTick = null;
    _lockoutRemaining = Duration.zero;
    final authState = ref.read(authStateServiceProvider);
    authState.setAuthenticated(true);
    authState.setIsLoggedIn(true);
    ref.read(pinGateProvider.notifier).unlock();
    ref.invalidate(accountsProvider);
    if (created) {
      await _maybeShowBiometricSetup();
    } else {
      _handleMainNavigation();
    }
  }

  /// One-time offer after code creation. Skipped on devices without
  /// biometrics, and never shown twice (flag kept in secure storage).
  Future<void> _maybeShowBiometricSetup() async {
    final store = ref.read(secureStoreProvider);
    try {
      final shown = await store.read('biometric_setup_shown');
      if (shown == '1' || !mounted) {
        _handleMainNavigation();
        return;
      }
      final supported =
          await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
      if (!supported || !mounted) {
        _handleMainNavigation();
        return;
      }
      await store.write('biometric_setup_shown', '1');
      // Hold the code screen briefly before the full-screen offer.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      final target =
          resumablePinTarget(widget.targetRoute ?? '') ?? Routes.home;
      context.go(
        '${Routes.biometricSetup}?target=${Uri.encodeQueryComponent(target)}',
      );
    } catch (_) {
      if (mounted) _handleMainNavigation();
    }
  }

  Future<void> _handleCodeEntry() async {
    if (_enteredCode.length != _codeLength) return;
    final verification = ref.read(verificationServiceProvider);

    if (isCreatingCode) {
      if (creationStage == 0) {
        creationStage = 1;
        createdCode = _enteredCode;
        setState(() => _enteredCode = '');
      } else if (creationStage == 1) {
        if (createdCode == _enteredCode) {
          await verification.storeHashedCode(
            _enteredCode,
            uid: ref.read(currentUserProvider)?.uid,
          );
          await _onAuthenticated(created: true);
        } else {
          setState(() => _enteredCode = '');
          _shakeController.forward(from: 0);
          if (mounted) {
            final l = AppLocalizations.of(context);
            showAppSnackBar(
              context,
              fromTop: true,
              endPositionOffset: 1,
              title: l.error,
              message: l.auWrongAccessCode,
            );
          }
        }
      }
      return;
    }

    final isValid = await verification.verifyAccessCode(_enteredCode);
    if (isValid) {
      await _onAuthenticated();
    } else {
      await _registerWrongCode();
    }
  }

  Future<void> _registerWrongCode() async {
    _lockout.registerFailure();
    // Only failure and reset write to storage; the 1s countdown only reads
    // the in-memory absolute release time.
    await _lockoutStore?.save(_lockout);
    if (!mounted) return;
    setState(() {
      _enteredCode = '';
      _lockoutRemaining = _lockout.remaining;
    });
    _shakeController.forward(from: 0);
    if (_lockoutRemaining > Duration.zero) {
      // The countdown replaces the dots, so it is the error message.
      _startLockoutTick();
    } else {
      final l = AppLocalizations.of(context);
      showAppSnackBar(
        context,
        fromTop: true,
        endPositionOffset: 1,
        title: l.error,
        message: l.auWrongAccessCode,
      );
    }
  }

  void _startLockoutTick() {
    _lockoutTick?.cancel();
    _lockoutTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _lockout.remaining;
      if (remaining <= Duration.zero) {
        _lockoutTick?.cancel();
        _lockoutTick = null;
      }
      setState(() => _lockoutRemaining = remaining);
    });
  }

  void _handleMainNavigation() {
    if (!context.mounted) return;
    final target = widget.targetRoute == null
        ? null
        : resumablePinTarget(widget.targetRoute!);
    context.go(target ?? Routes.home);
  }

  @override
  void dispose() {
    _lockoutTick?.cancel();
    _shakeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }
}

/// Horizontal pixel offset for the shake: four fast oscillations, exponentially
/// damped, forced to exactly zero at t=1 so a repeat can restart cleanly.
double _shakeOffset(double t) =>
    math.sin(t * math.pi * 8) * math.exp(-5 * t) * (1 - t) * 14;
