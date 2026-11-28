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

import 'package:tarlan_bank/views/shared/app_icons.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

/// Menu migrated to Riverpod: logout goes through AuthRepository and the
/// guest check through currentUserProvider; no GetX controllers.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static const _callBankAction = '__call_bank';

  List<MenuSection> _sections(AppLocalizations l) => [
    MenuSection(
      items: [
        MenuItem(
          icon: AppIcons.settings,
          title: l.securitySettings,
          routeArg: Routes.securitySettings,
        ),
        MenuItem(
          icon: AppIcons.accounts,
          title: l.navAccounts,
          routeArg: Routes.accounts,
        ),
      ],
    ),
    MenuSection(
      title: l.products,
      items: [
        MenuItem(icon: AppIcons.card, title: l.cards, routeArg: 'card'),
        MenuItem(
          icon: AppIcons.deposits,
          title: l.deposits,
          routeArg: 'deposit',
        ),
        MenuItem(icon: AppIcons.credits, title: l.credits, routeArg: 'credit'),
        MenuItem(
          icon: AppIcons.installment,
          title: l.installment,
          routeArg: 'transfer',
        ),
        MenuItem(
          icon: AppIcons.investments,
          title: l.investments,
          routeArg: Routes.investments,
        ),
      ],
    ),
    MenuSection(
      title: l.bankSection,
      items: [
        MenuItem(icon: AppIcons.atm, title: l.atm),
        MenuItem(icon: AppIcons.branch, title: l.branches),
        MenuItem(
          icon: AppIcons.phone,
          title: l.callBank,
          routeArg: _callBankAction,
        ),
        MenuItem(icon: AppIcons.support, title: l.supportTickets),
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
        case Routes.chatbot:
          navigateTo(context, Routes.chatbot);
        case Routes.accounts:
          navigateTo(context, Routes.accounts);
        case Routes.investments:
          navigateTo(context, Routes.investments);
        case null:
        case '':
          navigateTo(context, Routes.home);
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // MainShell supplies the 32/16 inset; only the floating top bar
          // needs extra clearance here.
          padding: const EdgeInsets.only(
            top: shellTopBarExtraTop,
            bottom: kBottomNavigationBarHeight * 2,
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
                  svgPath: AppIcons.exit,
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
                            AppIcons.exit,
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
