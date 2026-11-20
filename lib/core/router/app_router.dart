import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tarlan_bank/core/router/access_policy.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/routes/app_routes.dart' show Routes;
import 'package:tarlan_bank/views/auth/code_entering_screen.dart';
import 'package:tarlan_bank/views/auth/login_screen.dart';
import 'package:tarlan_bank/views/main/main_screen.dart';
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
import 'package:material_ui/material_ui.dart';

/// go_router skeleton (Week 1).
///
/// TRANSITIONAL: builders still point at the existing GetX screens, which read
/// `Get.arguments` internally. Each is replaced by a migrated ConsumerWidget in
/// Week 2. `MainScreen` keeps its internal bottom-nav for now; upgrading it to a
/// proper `StatefulShellRoute` (kitaphub pattern) is a Week 2 task.
///
/// The auth `redirect` is the real win here: declarative guarding driven by
/// [currentUserProvider], replacing GetX `AuthMiddleware`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthListenable();
  ref.listen(authStateProvider, (previous, next) => notifier.notify());

  final router = GoRouter(
    initialLocation: Routes.main,
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
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.codeEntering,
        builder: (context, state) => const CodeEnteringScreen(),
      ),
      GoRoute(
        path: Routes.main,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: Routes.chatbot,
        builder: (context, state) => const ChatBotScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.cardDetails,
        builder: (context, state) => const CardDetailsScreen(),
      ),
      GoRoute(
        path: Routes.createAccount,
        builder: (context, state) => CreateAccountScreen(
          accountType: state.uri.queryParameters['type'] ?? 'card',
        ),
      ),
      GoRoute(
        path: Routes.investments,
        builder: (context, state) => InvestmentsScreen(),
      ),
      GoRoute(
        path: Routes.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: Routes.phoneTransfer,
        builder: (context, state) => PhoneTransferScreen(),
      ),
      GoRoute(
        path: Routes.cardTransfer,
        builder: (context, state) => CardTransferScreen(),
      ),
      GoRoute(
        path: Routes.selfTransfer,
        builder: (context, state) => SelfTransferScreen(),
      ),
      GoRoute(
        path: Routes.convertation,
        builder: (context, state) => ConvertScreen(),
      ),
      GoRoute(
        path: Routes.qrTransfer,
        builder: (context, state) => QRTransferScreen(),
      ),
      GoRoute(
        path: Routes.paymentHistory,
        builder: (context, state) => PaymentHistoryScreen(),
      ),
      GoRoute(
        path: Routes.transferHistory,
        builder: (context, state) => TransferHistoryScreen(),
      ),
      GoRoute(
        path: Routes.transferDetails,
        builder: (context, state) => TransactionDetailsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
