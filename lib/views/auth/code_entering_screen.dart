import 'package:tarlan_bank/controllers/accounts_controller.dart';
import 'package:tarlan_bank/controllers/verification_controller.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/secure_store.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/utils/verification_dialog.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/user_settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../shared/widgets.dart';

class CodeEnteringScreen extends StatefulWidget {
  const CodeEnteringScreen({super.key});

  @override
  CodeEnteringScreenState createState() => CodeEnteringScreenState();
}

class CodeEnteringScreenState extends State<CodeEnteringScreen> {
  final AuthStateService _authState = Get.find<AuthStateService>();
  final UserRepository _userRepo = Get.find<UserRepository>();
  final VerificationController _verificationController = Get.find();
  final SecureStore _secureStore = Get.find<SecureStore>();
  final FocusNode _codeFocusNode = FocusNode();
  final LocalAuthentication _auth = LocalAuthentication();

  final int _codeLength = 4;
  String _enteredCode = '';
  int creationStage = 0;
  String createdCode = '';
  final Map<dynamic, dynamic> args = Get.arguments as Map;
  bool isCreatingCode = false;

  @override
  void initState() {
    isCreatingCode = args['isCreatingCode'] as bool? ?? false;
    init();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_secureStore.currentSettings?.useBiometrics == true &&
          !isCreatingCode) {
        _authenticateWithBiometrics();
      }
    });
    super.initState();
  }

  void init() async {
    isCreatingCode = !(await _verificationController.accessCodeExists());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 24.0, right: 24, top: 12.0),
          child: isLandscape
              ? _buildLandscapeLayout(theme, size)
              : _buildPortraitLayout(theme, size),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(ThemeData theme, Size size) {
    return Column(
      children: [
        _buildBackButton(theme),
        SizedBox(height: 12),
        SizedBox(
            width: size.width / 2,
            child: CustomCard(
                child: Center(
              child: buildUserCard(
                  _userRepo.currentUser?.fullName ?? '', theme, size),
            ))),
        SizedBox(height: 24),
        _buildAccessCodeLabel(theme),
        SizedBox(height: 16),
        _buildCodeIndicators(theme),
        SizedBox(height: 24),
        Expanded(child: _buildNumPad(theme, false, size)),
        _buildForgotCodeButton(theme),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout(ThemeData theme, Size size) {
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
                              _userRepo.currentUser?.fullName ?? '',
                              theme,
                              size)))),
              _buildForgotCodeButton(theme),
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
              Expanded(
                child: _buildNumPad(theme, true, size),
              ),
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
            onPressed: Navigator.of(context).canPop()
                ? Navigator.of(context).pop
                : null,
            // : authState.isAuthenticated
            // ? () => Navigator.of(context).pop()
            // : () => Get.toNamed('/login'),
          ),
        ));
  }

  Widget _buildAccessCodeLabel(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        isCreatingCode
            ? creationStage == 0
                ? "Придумайте код доступа"
                : "Повторите код доступа"
            : "Введите код доступа",
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
          margin: EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildNumPad(ThemeData theme, bool isLandscape, Size size) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxAvailableHeight = constraints.maxHeight;
      final double maxAvailableWidth = constraints.maxWidth;

      const int crossAxisCount = 3;
      const int mainAxisCount = 4;
      const double spacing = 12.0;

      final double totalSpacingHeight = (mainAxisCount - 1) * spacing;
      final double buttonHeight =
          (maxAvailableHeight - totalSpacingHeight) / mainAxisCount;

      final double desiredButtonWidth = buttonHeight;
      final double requiredTotalWidth = (crossAxisCount * desiredButtonWidth) +
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
            physics: NeverScrollableScrollPhysics(),
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
          physics: NeverScrollableScrollPhysics(),
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
    });
  }

  Widget _buildForgotCodeButton(ThemeData theme) {
    final isDisabled = isCreatingCode && creationStage == 0;

    void handleForgot() async {
      final verified = await showEmailConfirmationDialog(
        email: _userRepo.currentUser!.email,
        context: context,
      );
      if (verified) {
        setState(() {
          _enteredCode = '';
          createdCode = '';
          isCreatingCode = true;
          creationStage = 0;
        });
      }
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
              ? () async {
                  handleForgot();
                }
              : creationStage == 1
                  ? () {
                      _enteredCode = '';
                      createdCode = '';
                      setState(() {
                        creationStage = 0;
                      });
                    }
                  : () {},
      child: Text(
        _getButtonText(),
        style: theme.textTheme.titleSmall?.copyWith(
          color: isDisabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
              : theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  String _getButtonText() {
    if (isCreatingCode) {
      return 'Сбросить код доступа'; //AppLocalizations.of(context)!.resetAccessCode;  // Для многоязычности
    }
    return 'Забыли код доступа?'; // AppLocalizations.of(context)!.forgotAccessCode;
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
              setState(() {
                _enteredCode += value;
              });
              _handleCodeEntry();
            }
          },
          child: Center(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(ThemeData theme) {
    BorderRadius borderRadius = BorderRadius.circular(100);
    return (!isCreatingCode &&
            _secureStore.currentSettings?.useBiometrics == true)
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
                highlightColor:
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                onTap: () {
                  _authenticateWithBiometrics();
                },
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(4),
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
        : SizedBox();
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
                _enteredCode =
                    _enteredCode.substring(0, _enteredCode.length - 1);
              });
            }
          },
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(4),
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

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        if (_secureStore.currentSettings?.useBiometrics != true) {
          await _showBiometricDialog();
        }

        if (_secureStore.currentSettings?.useBiometrics == true) {
          authenticated = await _auth.authenticate(
            localizedReason: 'Используйте Touch ID для входа в суперприложение',
            biometricOnly: true,
            sensitiveTransaction: true,
            authMessages: <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: 'Вход в суперприложение',
                cancelButton: 'Отмена',
                signInHint: ' ',
              ),
              IOSAuthMessages(
                localizedFallbackTitle: 'Биометрическая аутентификация',
                cancelButton: 'Отмена',
              ),
            ],
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(context,
              fromTop: true,
              endPositionOffset: 1,
              title: 'Сообщение',
              message: 'Touch ID не поддерживается на этом устройстве');
        }
        print("Biometric authentication is not available");
      }
    } catch (e) {
      if (mounted &&
          e is LocalAuthException &&
          e.code != LocalAuthExceptionCode.userCanceled) {
        showAppSnackBar(context,
            fromTop: true,
            endPositionOffset: 1,
            title: 'Ошибка',
            message: 'Touch ID недоступен');
      }
    }

    if (authenticated) {
      _authState.setAuthenticated(true);
      _authState.setIsLoggedIn(true);
      _handleMainNavigation();
      Get.find<AccountsController>().fetchAccounts();
      print("Authentication successful!");
    } else {
      _authState.setIsLoggedIn(false);
      print("Authentication failed.");
    }
  }

  Future<void> _showBiometricDialog() async {
    final theme = Theme.of(context);

    return Get.dialog<void>(AlertDialog(
      title: Text(
        'Биометрическая Аутентификация',
        style: theme.textTheme.titleLarge,
      ),
      content: Text(
        'Вы хотите использовать биометрическую аутентификацию?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: theme.textButtonTheme.style,
          child: Text(
            'Нет',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () async {
            try {
              final currentSettings =
                  await _secureStore.loadSettings() ?? UserSettings.defaults();
              final updatedSettings =
                  currentSettings.copyWith(useBiometrics: true);
              _secureStore.saveSettings(updatedSettings);
            } finally {
              Get.back();
            }
          },
          style: theme.textButtonTheme.style,
          child: Text(
            'Да',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ));
  }

  void _handleCodeEntry() async {
    if (_enteredCode.length == _codeLength) {
      if (isCreatingCode) {
        if (creationStage == 0) {
          creationStage = 1;
          createdCode = _enteredCode;
          setState(() => _enteredCode = '');
        } else if (creationStage == 1) {
          if (createdCode == _enteredCode) {
            await _verificationController.storeHashedCode(_enteredCode);
            _authState.setAuthenticated(true);
            _authState.setIsLoggedIn(true);
            _handleMainNavigation();
            Get.find<AccountsController>().fetchAccounts();
          } else {
            setState(() => _enteredCode = '');
            if (mounted) {
              showAppSnackBar(context,
                  fromTop: true,
                  endPositionOffset: 1,
                  title: 'Ошибка',
                  message: 'Введен неверный код доступа');
            }
          }
        }
      } else {
        final isValid =
            await _verificationController.verifyAccessCode(_enteredCode);
        if (isValid) {
          _handleMainNavigation();
          _authState.setIsLoggedIn(true);
          Get.find<AccountsController>().fetchAccounts();
        } else {
          setState(() => _enteredCode = '');
          if (mounted) {
            showAppSnackBar(context,
                fromTop: true,
                endPositionOffset: 1,
                title: 'Ошибка',
                message: 'Введен неверный код доступа');
          }
        }
      }
    }
  }

  void _handleMainNavigation() {
    print('GOING ${args['targetRoute']}');
    if (args['targetRoute'] != null && args['targetRoute'] is String) {
      Get.offNamed('/main', arguments: args);
    } else {
      Get.offNamed('/main');
    }
  }

  @override
  void dispose() {
    _codeFocusNode.dispose();
    super.dispose();
  }
}
