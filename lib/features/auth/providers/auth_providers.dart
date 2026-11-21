import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarlan_bank/core/firebase/firestore_db.dart';

import '../data/auth_repository.dart';
import '../data/email_verification_cooldown_store.dart';
import '../data/auth_user.dart';
import '../data/firebase_auth_repository.dart';
import '../data/user_profile.dart';

/// Auth wiring (kitaphub-style composable providers).
///
/// `authRepositoryProvider` is the single swap point. Now: Firebase Auth
/// (project `tarlan-bank`, configured via FlutterFire). The router redirect
/// and any UI read the derived providers, never the backend.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = FirebaseAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Auth stream as an [AsyncValue].
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Currently signed-in user, or null.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Includes anonymous guests; use [isFullUserProvider] for registered users.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// True only for registered (email/password or Google) sessions.
final isFullUserProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && !user.isAnonymous;
});

/// Realtime `users/{uid}` profile; null for guests and signed-out users.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isAnonymous) return Stream.value(null);
  return tarlanFirestore()
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.exists ? UserProfile.fromFirestore(snap) : null);
});

/// Persisted 60s resend cooldown (spam protection) shared by all screens.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final verificationCooldownStoreProvider =
    FutureProvider<EmailVerificationCooldownStore>((ref) async {
      return EmailVerificationCooldownStore(
        await ref.watch(sharedPreferencesProvider.future),
      );
    });
