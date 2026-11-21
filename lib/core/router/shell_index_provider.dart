import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/router/auth_intent.dart';

/// Keeps the shell tab in sync with programmatic navigation (e.g. after a
/// create-account flow). Mirrors kitaphub's shell_index_provider.
class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 2; // Home tab

  void setIndex(int index) => state = index;
}

final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(
  ShellIndexNotifier.new,
);

/// One-shot target tab request from auth/create-account flows, replacing the
/// old AuthStateService targetRoute stream.
class PendingShellTabNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String tab) => state = tab;
  void clear() => state = null;
}

final pendingShellTabProvider =
    NotifierProvider<PendingShellTabNotifier, String?>(
      PendingShellTabNotifier.new,
    );

/// An overlay route requested from a cold/deep link. MainShell pushes it
/// after the shell is mounted so the branch underneath is preserved.
class PendingOverlayRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String route) => state = route;
  void clear() => state = null;
}

final pendingOverlayRouteProvider =
    NotifierProvider<PendingOverlayRouteNotifier, String?>(
      PendingOverlayRouteNotifier.new,
    );

/// One-shot auth intent: set when a guest/signed-out user attempts a
/// protected route, consumed by LoginPage after login/register/Google.
class PendingAuthIntentNotifier extends Notifier<AuthIntent?> {
  @override
  AuthIntent? build() => null;

  void request(AuthIntent intent) => state = intent;
  void clear() => state = null;
}

final pendingAuthIntentProvider =
    NotifierProvider<PendingAuthIntentNotifier, AuthIntent?>(
      PendingAuthIntentNotifier.new,
    );
