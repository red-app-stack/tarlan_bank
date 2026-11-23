import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/core/theme/theme_settings.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/services/auth_service.dart';
import 'package:tarlan_bank/services/screen_protect_service.dart';
import 'package:tarlan_bank/services/secure_store.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/utils/verification_dialog.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/shared_classes.dart';
import 'package:tarlan_bank/views/shared/user_settings.dart';

/// Security preferences. Every service is read from a Riverpod provider and
/// navigation/dialogs use go_router + showDialog, no GetX service locator.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  late final SecureStore _secureStore = ref.read(secureStoreProvider);
  late final AuthService _authService = ref.read(authServiceProvider);
  final LocalAuthentication _auth = LocalAuthentication();

  bool _authInProgress = false;
  bool _canCheckBiometrics = false;
  bool _deleting = false;

  final Map<String, bool> switchStates = {
    'assets/icons/ic_fingerprint.svg': false,
    'assets/icons/ic_screen_protect.svg': true,
    'assets/icons/ic_face.svg': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final settings = await _secureStore.loadSettings();
    if (settings != null && mounted) {
      setState(() {
        switchStates['assets/icons/ic_fingerprint.svg'] =
            settings.useBiometrics;
        switchStates['assets/icons/ic_screen_protect.svg'] =
            settings.screenProtection;
        switchStates['assets/icons/ic_face.svg'] = settings.biometricOperations;
      });
    }
    _canCheckBiometrics = await _auth.canCheckBiometrics;
  }

  Future<void> _saveSecuritySettings() async {
    final settings = UserSettings(
      themeMode: ref.read(themeModeProvider),
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

    await _secureStore.saveSettings(settings);
  }

  Future<bool> _authenticateWithBiometrics({String? hint}) async {
    final l = AppLocalizations.of(context);
    if (_authInProgress) return false;

    setState(() => _authInProgress = true);
    try {
      if (!_canCheckBiometrics && mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auBiometricUnavailableDevice,
        );
        return false;
      }

      return await _auth.authenticate(
        localizedReason: l.auBiometricAuthBody,
        biometricOnly: true,
        sensitiveTransaction: true,
        authMessages: [
          AndroidAuthMessages(
            signInHint: hint ?? ' ',
            signInTitle: l.auBiometricAuthTitle,
            cancelButton: l.cancel,
          ),
          IOSAuthMessages(
            localizedFallbackTitle: l.auBiometricFallbackTitle,
            cancelButton: l.cancel,
          ),
        ],
      );
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auBiometricUnavailable,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _authInProgress = false);
    }
  }

  Future<void> _handleSwitchToggle(String iconPath, bool newValue) async {
    final l = AppLocalizations.of(context);
    if (_authInProgress) return;

    if (newValue) {
      final authenticated = await _authenticateWithBiometrics(
        hint: l.auBiometricChangeHint,
      );
      if (!authenticated) {
        if (mounted) {
          showAppSnackBar(
            context,
            fromTop: true,
            endPositionOffset: 1,
            title: l.error,
            message: l.auBiometricAuthRequired,
          );
        }
        return;
      }
    }

    setState(() => switchStates[iconPath] = newValue);
    await _saveSecuritySettings();
  }

  Future<void> _handleItemTap(MenuItem item) async {
    final l = AppLocalizations.of(context);
    if (item.routeArg == null || !mounted) return;

    if (item.requiresAuth == true && _canCheckBiometrics) {
      try {
        final authenticated = await _authenticateWithBiometrics(
          hint: l.auBiometricChangeHint,
        );
        if (!authenticated) throw Exception('Auth failed');
        if (mounted) context.go(item.routeArg!);
      } catch (_) {
        if (mounted) {
          showAppSnackBar(
            context,
            fromTop: true,
            endPositionOffset: 1,
            title: l.error,
            message: l.auBiometricAuthRequired,
          );
        }
      }
    } else {
      context.go(item.routeArg!);
    }
  }

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await _authService.deleteUser();
      if (mounted) context.go(Routes.login);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auConfirmationRequired,
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _requestDelete() async {
    final l = AppLocalizations.of(context);
    try {
      if (_canCheckBiometrics) {
        if (await _authenticateWithBiometrics(hint: l.auDeleteConfirmHint)) {
          await _deleteAccount();
        }
      } else if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auEmailConfirmationRequired,
        );
        if (await showEmailConfirmationDialog(
          email: ref.read(currentUserProvider)?.email ?? '',
          context: context,
        )) {
          await _deleteAccount();
        }
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.auConfirmationRequired,
        );
      }
    }
  }

  List<MenuSection> _sections(AppLocalizations l) => [
    MenuSection(
      title: null,
      items: [
        MenuItem(
          icon: 'assets/icons/ic_lock.svg',
          title: l.auChangePassword,
          routeArg: Routes.changePassword,
          requiresAuth: true,
        ),
        MenuItem(
          icon: 'assets/icons/ic_accounts.svg',
          title: l.auLinkedAccounts,
          routeArg: Routes.linkedAccounts,
        ),
        MenuItem(
          icon: 'assets/icons/ic_access_code.svg',
          title: l.auChangeAccessCode,
          routeArg:
              '${Routes.codeEntering}?mode=create&target='
              '${Uri.encodeQueryComponent(Routes.menuSecurity)}',
          requiresAuth: true,
        ),
        MenuItem(
          icon: 'assets/icons/ic_fingerprint.svg',
          title: l.auAuthorizationTitle,
          description: l.auBiometricLoginDesc,
          endElement: 'switch',
        ),
        MenuItem(
          icon: 'assets/icons/ic_screen_protect.svg',
          title: l.auScreenProtectionTitle,
          description: l.auScreenProtectionDesc,
          endElement: 'switch',
        ),
        MenuItem(
          icon: 'assets/icons/ic_face.svg',
          title: l.auBiometricOperationsTitle,
          description: l.auBiometricOperationsDesc,
          endElement: 'switch',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final sections = _sections(l);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            spacing: 24,
            children: [
              CustomCard(
                label: l.securitySettings,
                padding: const EdgeInsets.all(4),
                mainAxisAlignment: MainAxisAlignment.start,
                startWidget: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/ic_back.svg',
                    width: 36,
                    height: 36,
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
              ...sections.map(
                (section) => Column(
                  children: [
                    CustomCard(
                      label: section.title,
                      labelStyle: theme.textTheme.titleLarge,
                      padding: EdgeInsets.zero,
                      topRowPadding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                      ),
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
                                    activeTrackColor: theme.colorScheme.primary,
                                    inactiveThumbColor: theme
                                        .colorScheme
                                        .surfaceContainerLowest,
                                    inactiveTrackColor: theme
                                        .extension<Extra>()
                                        ?.tertiaryText,
                                    trackOutlineColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                  )
                                : const SizedBox(),
                            onTap: isSwitch ? null : () => _handleItemTap(item),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: () {},
                  onTap: _requestDelete,
                  borderRadius: BorderRadius.circular(30),
                  splashFactory: InkRipple.splashFactory,
                  splashColor: theme.colorScheme.error.withValues(alpha: 0.08),
                  highlightColor: theme.colorScheme.error.withValues(
                    alpha: 0.04,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l.auDeleteAccountRequest,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
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
