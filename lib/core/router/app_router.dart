import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/access_policy.dart';
import 'package:tarlan_bank/core/router/auth_intent.dart';
import 'package:tarlan_bank/core/router/app_navigation.dart'
    show rootNavigatorKey;
import 'package:tarlan_bank/core/router/face_gate.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart';
import 'package:tarlan_bank/core/router/routes.dart'
    show Routes, isShellOverlayPush;
import 'package:tarlan_bank/core/router/shell_index_provider.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/auth/providers/face_gate_provider.dart';
import 'package:tarlan_bank/features/auth/providers/pin_gate_provider.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/auth/biometric_setup_screen.dart';
import 'package:tarlan_bank/views/auth/code_entering_screen.dart';
import 'package:tarlan_bank/views/auth/face_verification_screen.dart';
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
import 'package:tarlan_bank/views/shared/placeholder_screen.dart';
import 'package:tarlan_bank/views/transactions/card_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/convert_screen.dart';
import 'package:tarlan_bank/views/transactions/phone_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/qr_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/self_transfer_screen.dart';
import 'package:tarlan_bank/views/transactions/transaction_details_screen.dart';
import 'package:tarlan_bank/views/transactions/transfer_history_screen.dart';

CustomTransitionPage<void> _overlayPage({
  required LocalKey key,
  required Widget child,
  required bool fromLeft,
}) => _slidePage(
  key: key,
  child: child,
  begin: fromLeft ? const Offset(-1, 0) : const Offset(1, 0),
);

CustomTransitionPage<void> _slidePage({
  required LocalKey key,
  required Widget child,
  required Offset begin,
  Duration duration = const Duration(milliseconds: 200),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _nestedPage({
  required LocalKey key,
  required Widget child,
}) => _slidePage(key: key, child: child, begin: const Offset(1, 0));

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthListenable();
  ref.listen(authStateProvider, (_, _) => notifier.notify());
  ref.listen(pinGateProvider, (_, _) => notifier.notify());
  ref.listen(faceGateProvider, (_, _) => notifier.notify());

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authLevel = accessLevel(ref.read(authStateProvider));
      final gate = ref.read(pinGateProvider).status;
      final location = state.matchedLocation;
      final uri = state.uri.toString();

      // The internal loading route hands off once the storage check ends.
      if (location == Routes.loading) {
        final exit = loadingExitFor(
          authLevel: authLevel,
          gate: gate,
          target: state.uri.queryParameters['target'],
        );
        if (exit != null) return exit;
      }

      // PIN comes FIRST: create it on a new device or confirm it on a new
      // login. Only then does the face check run, so the two gates cannot
      // bounce between /codeEntering and /faceVerify forever.
      final challenge = pinRequired(authLevel, gate);
      final face = ref.read(faceGateProvider);
      final faceChallenge = faceRequired(authLevel, face.status) && !challenge;

      if (location == Routes.faceVerify && !faceChallenge) {
        return resumableFaceTarget(state.uri.queryParameters['target']) ??
            Routes.home;
      }
      if (faceChallenge &&
          !faceExempt(location, scanAfterPin: face.scanAfterPin)) {
        return faceRouteFor(uri);
      }

      // PIN is a feature gate, not an app gate: without it the user keeps
      // guest routes; protected money features challenge for PIN/setup.
      final level = challenge ? AccessLevel.guest : authLevel;
      final redirect = redirectFor(level: level, location: location);
      if (challenge && redirect == Routes.login) {
        return pinChallengeFor(gate: gate, location: uri);
      }

      // Cold/deep link to an overlay: land on the shell first, then let
      // MainShell push the overlay so the branch underneath is preserved.
      if (level == AccessLevel.full &&
          (location == Routes.profile || location == Routes.chatbot) &&
          !isShellOverlayPush(state.extra)) {
        ref.read(pendingOverlayRouteProvider.notifier).request(location);
        return Routes.home;
      }
      if (redirect == Routes.login &&
          shouldRememberAuthIntent(level, location)) {
        ref
            .read(pendingAuthIntentProvider.notifier)
            .request(AuthIntent(target: location, origin: Routes.home));
      }
      return redirect;
    },
    routes: [
      GoRoute(
        path: Routes.loading,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      // Legacy alias: email-verification deep links still navigate to /main,
      // and the PIN challenge keeps it as the resume target. Without this
      // redirect the post-PIN context.go('/main') hits the errorBuilder.
      GoRoute(path: Routes.main, redirect: (_, _) => Routes.home),
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, state) =>
            _fadePage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: Routes.verifyLink,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const VerificationLinkScreen(),
        ),
      ),
      GoRoute(
        path: Routes.verifyAction,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: const VerificationLinkScreen(),
        ),
      ),
      GoRoute(
        path: Routes.codeEntering,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: CodeEnteringScreen(
            createCode: state.uri.queryParameters['mode'] == 'create',
            resetCode: state.uri.queryParameters['mode'] == 'reset',
            targetRoute: state.uri.queryParameters['target'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.faceVerify,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: FaceVerificationScreen(
            targetRoute: state.uri.queryParameters['target'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.biometricSetup,
        pageBuilder: (_, state) => _fadePage(
          key: state.pageKey,
          child: BiometricSetupScreen(
            targetRoute: state.uri.queryParameters['target'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        pageBuilder: (_, state) => _overlayPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          fromLeft: true,
        ),
      ),
      GoRoute(
        path: Routes.chatbot,
        pageBuilder: (_, state) => _overlayPage(
          key: state.pageKey,
          child: const ChatBotScreen(),
          fromLeft: false,
        ),
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
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: PaymentHistoryScreen(),
                    ),
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
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: PhoneTransferScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'self',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: SelfTransferScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'card',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: CardTransferScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'convert',
                    pageBuilder: (_, state) =>
                        _nestedPage(key: state.pageKey, child: ConvertScreen()),
                  ),
                  GoRoute(
                    path: 'qr',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: QRTransferScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: TransferHistoryScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'details',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: TransactionDetailsScreen(),
                    ),
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
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: CreateAccountScreen(
                        accountType:
                            state.uri.queryParameters['type'] ?? 'card',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'details',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: CardDetailsScreen(),
                    ),
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
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: const SecuritySettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'investments',
                    pageBuilder: (_, state) => _nestedPage(
                      key: state.pageKey,
                      child: InvestmentsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'changePassword',
                    pageBuilder: (context, state) => _nestedPage(
                      key: state.pageKey,
                      child: PlaceholderScreen(
                        title: AppLocalizations.of(context).changePasswordTitle,
                        message: AppLocalizations.of(context)
                            .featurePlaceholderBody,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'linkedAccounts',
                    pageBuilder: (context, state) => _nestedPage(
                      key: state.pageKey,
                      child: PlaceholderScreen(
                        title: AppLocalizations.of(context).linkedAccountsTitle,
                        message: AppLocalizations.of(context)
                            .featurePlaceholderBody,
                      ),
                    ),
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
