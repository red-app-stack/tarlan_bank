import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/access_policy.dart';
import 'package:tarlan_bank/core/router/app_navigation.dart'
    show rootNavigatorKey;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/auth/code_entering_screen.dart';
import 'package:tarlan_bank/views/auth/login_screen.dart';
import 'package:tarlan_bank/views/auth/verification_link_screen.dart';
import 'package:tarlan_bank/views/main/home_screen.dart';
import 'package:tarlan_bank/views/main/main_shell.dart';
import 'package:tarlan_bank/views/main/menu_screen.dart';
import 'package:tarlan_bank/views/main/accounts_screen.dart';
import 'package:tarlan_bank/views/main/payments_screen.dart';
import 'package:tarlan_bank/views/main/transfers_screen.dart';
import 'package:tarlan_bank/views/other/card_details_screen.dart';
import 'package:tarlan_bank/views/other/chatbot_screen.dart';
import 'package:tarlan_bank/views/other/create_account_screen.dart';
import 'package:tarlan_bank/views/other/investments_screen.dart';
import 'package:tarlan_bank/views/other/profile_screen.dart';
import 'package:tarlan_bank/views/other/security_settings_screen.dart';
import 'package:tarlan_bank/views/payments/payment_history_screen.dart';
import 'package:tarlan_bank/views/transactions/card_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/convert_screen.dart';
import 'package:tarlan_bank/views/transactions/phone_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/qr_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/self_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/transaction_details_screen.dart';
import 'package:tarlan_bank/views/transactions/transfer_history_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthListenable();
  ref.listen(authStateProvider, (_, _) => notifier.notify());

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return redirectFor(
        level: accessLevel(auth),
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: Routes.loading,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: Routes.login, builder: (_, state) => const LoginPage()),
      GoRoute(
        path: Routes.verifyLink,
        builder: (_, state) => const VerificationLinkScreen(),
      ),
      GoRoute(
        path: Routes.verifyAction,
        builder: (_, state) => const VerificationLinkScreen(),
      ),
      GoRoute(
        path: Routes.codeEntering,
        builder: (_, state) => const CodeEnteringScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            Stack(
              children: List.generate(children.length, (index) {
                return AnimatedOpacity(
                  opacity: index == navigationShell.currentIndex ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: index != navigationShell.currentIndex,
                    child: children[index],
                  ),
                );
              }),
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.payments,
                builder: (_, state) => PaymentsScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (_, state) => PaymentHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.transfers,
                builder: (_, state) => TransfersScreen(),
                routes: [
                  GoRoute(
                    path: 'phone',
                    builder: (_, state) => PhoneTransferScreen(),
                  ),
                  GoRoute(
                    path: 'self',
                    builder: (_, state) => SelfTransferScreen(),
                  ),
                  GoRoute(
                    path: 'card',
                    builder: (_, state) => CardTransferScreen(),
                  ),
                  GoRoute(
                    path: 'convert',
                    builder: (_, state) => ConvertScreen(),
                  ),
                  GoRoute(
                    path: 'qr',
                    builder: (_, state) => QRTransferScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (_, state) => TransferHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'details',
                    builder: (_, state) => TransactionDetailsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.accounts,
                builder: (_, state) => AccountsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (_, state) => CreateAccountScreen(
                      accountType: state.uri.queryParameters['type'] ?? 'card',
                    ),
                  ),
                  GoRoute(
                    path: 'details',
                    builder: (_, state) => CardDetailsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.menu,
                builder: (_, _) => const MenuScreen(),
                routes: [
                  GoRoute(
                    path: 'security',
                    builder: (_, _) => const SecuritySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'investments',
                    builder: (_, _) => InvestmentsScreen(),
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'chatbot',
                    builder: (_, _) => const ChatBotScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(AppLocalizations.of(context).errorGeneric)),
    ),
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
