import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/features/auth/data/auth_user.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

/// Route access policy for go_router (product decision 2026-11-20).
///
/// - signed out: auth screens only.
/// - guest (Firebase anonymous): main/menu, exchange rates, notifications.
///   No accounts, transfers, history, profile, cards or settings.
/// - full user: everything; login redirects to main.
///
/// Pure so the policy is unit-testable without a widget or Firebase app.
enum AccessLevel { loading, signedOut, guest, full }

const Set<String> publicRoutes = {
  Routes.login,
  Routes.reauth,
  Routes.codeEntering,
  Routes.verifyLink,
  Routes.verifyAction,
  Routes.loading,
};

/// Guest-visible routes. "Menu" is a tab inside [Routes.main], not a route.
/// Notifications have no route yet (currently behind profile) — add it here
/// when the screen is promoted for guests.
const Set<String> guestRoutes = {
  Routes.home,
  Routes.menu,
  Routes.convertation,
  ...publicRoutes,
};

AccessLevel accessLevel(AsyncValue<AuthUser?> auth) {
  if (auth.isLoading) return AccessLevel.loading;
  final user = auth.value;
  if (user == null) return AccessLevel.signedOut;
  return user.isAnonymous ? AccessLevel.guest : AccessLevel.full;
}

/// Returns the redirect target, or null when navigation may proceed.
String? redirectFor({required AccessLevel level, required String location}) {
  switch (level) {
    case AccessLevel.loading:
      return null; // auth stream still resolving: don't bounce anyone
    case AccessLevel.signedOut:
      return publicRoutes.contains(location) ? null : Routes.login;
    case AccessLevel.guest:
      return guestRoutes.contains(location) ? null : Routes.login;
    case AccessLevel.full:
      return location == Routes.login ? Routes.home : null;
  }
}

/// Whether a denial should remember the destination for after auth.
/// Anonymous sign-in is explicitly not an auth success for this purpose.
bool shouldRememberAuthIntent(AccessLevel level, String location) {
  if (level == AccessLevel.full || level == AccessLevel.loading) return false;
  return !publicRoutes.contains(location) && !guestRoutes.contains(location);
}
