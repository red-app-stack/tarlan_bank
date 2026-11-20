import 'package:tarlan_bank/controllers/auth_controller.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/utils/verification_dialog.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:tarlan_bank/services/screen_protect_service.dart';
import '../../controllers/theme_controller.dart';
import '../../services/secure_store.dart';
import '../shared/shared_classes.dart';
import '../shared/user_settings.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  SecuritySettingsScreenState createState() => SecuritySettingsScreenState();
}

class SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final secureStore = Get.find<SecureStore>();
  final LocalAuthentication _auth = LocalAuthentication();
  final UserRepository _userRepo = Get.find();
  bool _authInProgress = false;
  bool canCheckBiometrics = false;

  final Map<String, bool> switchStates = {
    'assets/icons/ic_fingerprint.svg': false,
    'assets/icons/ic_screen_protect.svg': true,
    'assets/icons/ic_face.svg': false,
  };

  final List<MenuSection> sections = [
    MenuSection(
      title: null,
      items: [
        MenuItem(
            icon: 'assets/icons/ic_lock.svg',
            title: 'Смена пароля',
            routeArg: '/changePassword',
            requiresAuth: true),
        MenuItem(
            icon: 'assets/icons/ic_accounts.svg',
            title: 'Связанные аккаунты',
            routeArg: '/linkedAccounts'),
        MenuItem(
            icon: 'assets/icons/ic_access_code.svg',
            title: 'Изменить код доступа',
            routeArg: '/codeEntering',
            args: {'isCreatingCode': true},
            requiresAuth: true),
        MenuItem(
            icon: 'assets/icons/ic_fingerprint.svg',
            title: 'Авторизация',
            description: 'Вход в приложение с биометрией',
            endElement: 'switch'),
        MenuItem(
            icon: 'assets/icons/ic_screen_protect.svg',
            title: 'Защита от записи экрана',
            description: 'Скриншоты и запись экрана',
            endElement: 'switch'),
        MenuItem(
            icon: 'assets/icons/ic_face.svg',
            title: 'Операции с биометрией',
            description: 'Подтверждение переводов',
            endElement: 'switch'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final settings = await secureStore.loadSettings();
    if (settings != null) {
      setState(() {
        switchStates['assets/icons/ic_fingerprint.svg'] =
            settings.useBiometrics;
        switchStates['assets/icons/ic_screen_protect.svg'] =
            settings.screenProtection;
        switchStates['assets/icons/ic_face.svg'] = settings.biometricOperations;
      });
    }
    canCheckBiometrics = await _auth.canCheckBiometrics;
  }

  Future<void> _saveSecuritySettings() async {
    final settings = UserSettings(
      themeMode: Get.find<ThemeController>().themeMode.value,
      useBiometrics: switchStates['assets/icons/ic_fingerprint.svg'] ?? false,
      screenProtection:
          switchStates['assets/icons/ic_screen_protect.svg'] ?? false,
      biometricOperations: switchStates['assets/icons/ic_face.svg'] ?? false,
    );

    if (switchStates['assets/icons/ic_screen_protect.svg'] ?? true) {
      await ScreenProtect.enable();
    } else {
      await ScreenProtect.disable();
    }

    await secureStore.saveSettings(settings);
  }

  Future<bool> showBiometricDialog() async {
    final theme = Theme.of(context);

    final bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Удаление учётной записи',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          'Вы уверены что хотите удалить учётную запись?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
              Get.back(result: false);
            },
            style: theme.textButtonTheme.style,
            child: Text(
              'Нет',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              try {
                if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                Get.back(result: true);
              } catch (e) {
                Get.back(result: false);
              }
            },
            style: theme.textButtonTheme.style,
            child: Text(
              'Да',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  Future<bool> _authenticateWithBiometrics({String? hint = ' '}) async {
    if (_authInProgress) return false;

    setState(() => _authInProgress = true);
    try {
      if (!canCheckBiometrics && mounted) {
        showAppSnackBar(context,
            fromTop: true,
            endPositionOffset: 1,
            title: 'Ошибка',
            message: 'Биометрия недоступна на этом устройстве');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Подтвердите вашу личность',
        biometricOnly: true,
        sensitiveTransaction: true,
        authMessages: [
          AndroidAuthMessages(
              signInHint: hint,
              signInTitle: 'Биометрическая аутентификация',
              cancelButton: 'Отмена'),
          IOSAuthMessages(
              localizedFallbackTitle: 'Биометрическая аутентификация',
              cancelButton: 'Отмена'),
        ],
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            fromTop: true,
            endPositionOffset: 1,
            title: 'Ошибка',
            message: 'Биометрия недоступна');
      }
      return false;
    } finally {
      setState(() => _authInProgress = false);
    }
  }

  Future<void> _handleSwitchToggle(String iconPath, bool newValue) async {
    if (_authInProgress) return;

    if (newValue) {
      final authenticated = await _authenticateWithBiometrics(
          hint: 'Изменение требует авторизации');
      if (!authenticated) {
        if (mounted) {
          showAppSnackBar(context,
              fromTop: true,
              endPositionOffset: 1,
              title: 'Ошибка',
              message: 'Необходимо подтверждение биометрией');
        }
        return;
      }
    }

    setState(() => switchStates[iconPath] = newValue);
    await _saveSecuritySettings();
  }

  Future<void> _handleItemTap(MenuItem item) async {
    if (item.routeArg == null) return;

    if (item.requiresAuth == true && canCheckBiometrics) {
      try {
        final authenticated = await _authenticateWithBiometrics(
            hint: 'Изменение требует авторизации');
        if (!authenticated) throw Exception('Auth failed');
        Get.offNamed(item.routeArg!, arguments: item.args);
      } catch (_) {
        if (mounted) {
          showAppSnackBar(context,
              fromTop: true,
              endPositionOffset: 1,
              title: 'Ошибка',
              message: 'Необходимо подтверждение биометрией');
        }
      }
    } else {
      Get.offNamed(item.routeArg!, arguments: item.args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            spacing: 24,
            children: [
              CustomCard(
                label: 'Безопасность',
                padding: const EdgeInsets.all(4),
                mainAxisAlignment: MainAxisAlignment.start,
                startWidget: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/ic_back.svg',
                    width: 36,
                    height: 36,
                    colorFilter: ColorFilter.mode(
                        theme.colorScheme.primary, BlendMode.srcIn),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              ...sections.map((section) => Column(
                    children: [
                      CustomCard(
                        label: section.title,
                        labelStyle: theme.textTheme.titleLarge,
                        padding: EdgeInsets.zero,
                        topRowPadding:
                            const EdgeInsets.only(left: 16, right: 16, top: 16),
                        child: Column(
                          children: section.items.map((item) {
                            final isSwitch = item.endElement == 'switch';
                            return ListItem.vertical(
                              svgPath: item.icon,
                              iconSize: 36,
                              title: item.title,
                              subtitle: item.description,
                              trailing: isSwitch
                                  ? Switch(
                                      value: switchStates[item.icon] ?? false,
                                      onChanged: (value) =>
                                          _handleSwitchToggle(item.icon, value),
                                      activeThumbColor:
                                          theme.colorScheme.onPrimary,
                                      activeTrackColor:
                                          theme.colorScheme.primary,
                                      inactiveThumbColor: theme
                                          .colorScheme.surfaceContainerLowest,
                                      inactiveTrackColor: theme
                                          .extension<Extra>()
                                          ?.tertiaryText,
                                      trackOutlineColor:
                                          WidgetStateProperty.all(
                                              Colors.transparent),
                                    )
                                  : SizedBox(),
                              onTap:
                                  isSwitch ? null : () => _handleItemTap(item),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                    ],
                  )),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: () async {},
                  onTap: () async {
                    try {
                      if (canCheckBiometrics) {
                        if (await _authenticateWithBiometrics(
                            hint: 'Подтвердите удаление учетной записи.')) {
                          Get.find<AuthController>().deleteAccount();
                        }
                      } else {
                        if (context.mounted) {
                          showAppSnackBar(context,
                              fromTop: true,
                              endPositionOffset: 1,
                              title: 'Ошибка',
                              message: 'Необходимо подтверждение почтой');

                          if (await showEmailConfirmationDialog(
                              email: _userRepo.currentUser?.email ?? '',
                              context: context)) {
                            Get.find<AuthController>().deleteAccount();
                          }
                        }
                      }
                    } catch (_) {
                      if (context.mounted) {
                        showAppSnackBar(context,
                            fromTop: true,
                            endPositionOffset: 1,
                            title: 'Ошибка',
                            message: 'Необходимо подтверждение');
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  splashFactory: InkRipple.splashFactory,
                  splashColor: theme.colorScheme.error.withValues(alpha: 0.08),
                  highlightColor:
                      theme.colorScheme.error.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Запросить удаление учётной записи',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
