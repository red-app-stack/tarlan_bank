import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';

import '../providers/auth_providers.dart';

/// Deletes the Firebase account and every uid-owned record, then clears all
/// device-local login state. Shared by the security screen and the reauth
/// screen so the two entry points cannot drift apart.
Future<void> deleteAccountAndReset(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).deleteAccount();
  // Token, cached user, PIN, lockout and face flag all live in secure storage.
  await ref.read(secureStoreProvider).deleteAll();
  final authState = ref.read(authStateServiceProvider);
  authState.setAuthenticated(false);
  authState.setIsLoggedIn(false);
  authState.setChecking(false);
}
