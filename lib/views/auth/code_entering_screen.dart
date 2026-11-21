import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/verification_dialog.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/user_settings.dart';

import '../shared/widgets.dart';

/// Access-code gate. All dependencies arrive through Riverpod providers and
/// navigation uses go_router. The router builds this screen with no arguments;
/// [createCode] and [targetRoute] are optional and safely defaulted.
class CodeEnteringScreen extends ConsumerStatefulWidget {
  const CodeEnteringScreen({
    super.key,
    this.createCode = false,
    this.targetRoute,
  });

  final bool createCode;
  final String? targetRoute;

  @override
  ConsumerState<CodeEnteringScreen> createState() => CodeEnteringScreenState();
}

class CodeEnteringScreenState extends ConsumerState<CodeEnteringScreen> {
  final FocusNode _codeFocusNode = FocusNode();
  final LocalAuthentication _auth = LocalAuthentication();

  final int _codeLength = 4;
  String _enteredCode = '';
  int creationStage = 0;
  String createdCode = '';
  bool isCreatingCode = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final store = ref.read(secureStoreProvider);
    await store.loadSettings();
    final verification = ref.read(verificationServiceProvider);
    var creating = widget.createCode;
    if (!creating) creating = !(await verification.accessCodeExists());
    if (!mounted) return;
    setState(() {
      isCreatingCode = creating;
      _biometricsEnabled = store.currentSettings?.useBiometrics == true;
    });
    if (_biometricsEnabled && !isCreatingCode) {
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
    final userRepo = ref.watch(userRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24, top: 12.0),
          child: isLandscape
              ? _buildLandscapeLayout(theme, size, userRepo)
              : _buildPortraitLayout(theme, size, userRepo),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(ThemeData theme, Size size, dynamic userRepo) {
    return Column(
      children: [
        _buildBackButton(theme),
        const SizedBox(height: 12),
        SizedBox(
          width: size.width / 2,
          child: CustomCard(
            child: Center(
              child: buildUserCard(
                userRepo.currentUser?.fullName ?? '',
                theme,
                size,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildAccessCodeLabel(theme),
        const SizedBox(height: 16),
        _buildCodeIndicators(theme),
        const SizedBox(height: 24),
        Expanded(child: _buildNumPad(theme, size)),
        _buildForgotCodeButton(theme, userRepo),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout(ThemeData theme, Size size, dynamic userRepo) {
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
                  child: Center(
                    child: buildUserCard(
                      userRepo.currentUser?.fullName ?? '',
                      theme,
                      size,
                    ),
                  ),
                ),
              ),
              _buildForgotCodeButton(theme, userRepo),
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

  Widget _buildCodeIndicators(ThemeData theme) {
    return Row(
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

  Widget _buildForgotCodeButton(ThemeData theme, dynamic userRepo) {
    final l = AppLocalizations.of(context);
    final isDisabled = isCreatingCode && creationStage == 0;

    Future<void> handleForgot() async {
      final verified = await showEmailConfirmationDialog(
        email: userRepo.currentUser?.email ?? '',
        context: context,
      );
      if (!verified || !mounted) return;
      setState(() {
        _enteredCode = '';
        createdCode = '';
        isCreatingCode = true;
        creationStage = 0;
      });
    }

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
          ? handleForgot
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
    BorderRadius borderRadius = BorderRadius.circular(100);
    return Container(
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
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          onTap: () {
            if (_enteredCode.length < _codeLength) {
              setState(() => _enteredCode += value);
              _handleCodeEntry();
            }
          },
          child: Center(
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(ThemeData theme) {
    BorderRadius borderRadius = BorderRadius.circular(100);
    return (!isCreatingCode && _biometricsEnabled)
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
                    child: SvgPicture.asset(
                      'assets/icons/ic_biometry.svg',
                      width: 48,
                      height: 48,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildDeleteButton(ThemeData theme) {
    BorderRadius borderRadius = BorderRadius.circular(100);
    return Container(
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
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          onTap: () {
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
                  theme.colorScheme.primary,
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

  Future<void> _onAuthenticated() async {
    final authState = ref.read(authStateServiceProvider);
    authState.setAuthenticated(true);
    authState.setIsLoggedIn(true);
    ref.invalidate(accountsProvider);
    _handleMainNavigation();
  }

  Future<void> _handleCodeEntry() async {
    if (_enteredCode.length != _codeLength) return;
    final verification = ref.read(verificationServiceProvider);
    final l = AppLocalizations.of(context);

    if (isCreatingCode) {
      if (creationStage == 0) {
        creationStage = 1;
        createdCode = _enteredCode;
        setState(() => _enteredCode = '');
      } else if (creationStage == 1) {
        if (createdCode == _enteredCode) {
          await verification.storeHashedCode(_enteredCode);
          await _onAuthenticated();
        } else {
          setState(() => _enteredCode = '');
          if (mounted) {
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
      setState(() => _enteredCode = '');
      if (mounted) {
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

  void _handleMainNavigation() {
    if (context.mounted) context.go(widget.targetRoute ?? Routes.home);
  }

  @override
  void dispose() {
    _codeFocusNode.dispose();
    super.dispose();
  }
}
