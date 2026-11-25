import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/svg.dart';

import 'package:tarlan_bank/core/providers/notification_providers.dart'
    show notificationServiceProvider;
import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/utils/phone_launcher.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

import '../shared/custom_card.dart';
import '../shared/list_item.dart';
import '../shared/shared_classes.dart';
import '../shared/app_snack_bar.dart';

/// Menu migrated to Riverpod: logout goes through AuthRepository and the
/// guest check through currentUserProvider; no GetX controllers.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static const _callBankAction = '__call_bank';

  List<MenuSection> _sections(AppLocalizations l) => [
    MenuSection(
      items: [
        MenuItem(
          icon: 'assets/icons/ic_settings.svg',
          title: l.securitySettings,
          routeArg: Routes.securitySettings,
        ),
      ],
    ),
    MenuSection(
      title: l.products,
      items: [
        MenuItem(
          icon: 'assets/icons/ic_card.svg',
          title: l.cards,
          routeArg: 'card',
        ),
        MenuItem(
          icon: 'assets/icons/ic_deposit.svg',
          title: l.deposits,
          routeArg: 'deposit',
        ),
        MenuItem(
          icon: 'assets/icons/ic_credit.svg',
          title: l.credits,
          routeArg: 'credit',
        ),
        MenuItem(
          icon: 'assets/icons/ic_installment.svg',
          title: l.installment,
          routeArg: 'transfer',
        ),
        MenuItem(
          icon: 'assets/icons/ic_invest.svg',
          title: l.investments,
          routeArg: Routes.investments,
        ),
      ],
    ),
    MenuSection(
      title: l.bankSection,
      items: [
        MenuItem(icon: 'assets/icons/ic_atm.svg', title: l.atm),
        MenuItem(icon: 'assets/icons/ic_branch.svg', title: l.branches),
        MenuItem(
          icon: 'assets/icons/ic_phone.svg',
          title: l.callBank,
          routeArg: _callBankAction,
        ),
        MenuItem(icon: 'assets/icons/ic_support.svg', title: l.supportTickets),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final sections = _sections(l);
    final user = ref.watch(currentUserProvider);

    Future<void> logout() async {
      // DELETE needs the Firebase ID token, so drop the server registration
      // before AuthInterceptor loses the signed-in user.
      await ref.read(notificationServiceProvider).stop();
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) await navigateReset(context, Routes.login);
    }

    Future<void> handleItemClick(String? routeArg) async {
      switch (routeArg) {
        case _callBankAction:
          try {
            await launchSupportDialer();
          } catch (e) {
            debugPrint(e.toString());
            if (context.mounted) {
              showAppSnackBar(
                context,
                fromTop: true,
                endPositionOffset: 1,
                title: l.error,
                message: l.callFailed,
              );
            }
          }
          return;
        case Routes.securitySettings:
          navigateTo(context, Routes.securitySettings);
        case Routes.investments:
          navigateTo(context, Routes.investments);
        case null:
        case '':
          navigateToMainTab(context, '/accounts');
        default:
          if (user == null || user.isAnonymous) {
            navigateTo(context, Routes.login);
          } else {
            navigateTo(
              context,
              Routes.createAccount,
              arguments: {'extra': routeArg},
            );
          }
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 56 + kToolbarHeight,
          ),
          child: Column(
            spacing: 24,
            children: [
              CustomCard(
                label: user != null && user.isAnonymous ? l.menuGuest : l.menu,
                padding: const EdgeInsets.all(18),
              ),
              ...sections.map(
                (section) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...section.items.map(
                            (item) => ListItem.vertical(
                              svgPath: item.icon,
                              iconSize: 36,
                              title: item.title,
                              subtitle: item.description,
                              onTap: () => handleItemClick(item.routeArg),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (user == null)
                ListItem.vertical(
                  svgPath: 'assets/icons/ic_exit.svg',
                  iconSize: 36,
                  title: l.signIn,
                  onTap: () => navigateTo(context, Routes.login),
                )
              else
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: logout,
                    borderRadius: BorderRadius.circular(30),
                    splashFactory: InkRipple.splashFactory,
                    splashColor: theme.colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                    highlightColor: theme.colorScheme.primary.withValues(
                      alpha: 0.04,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_exit.svg',
                            width: 36,
                            height: 36,
                            colorFilter: ColorFilter.mode(
                              theme.colorScheme.error,
                              BlendMode.srcIn,
                            ),
                          ),
                          Text(
                            l.logout,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
