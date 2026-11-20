import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/auth_user.dart';
import '../data/firebase_auth_repository.dart';

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

/// Raw auth stream as an [AsyncValue] (loading/data/error handled by consumers).
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Currently signed-in user, or null.
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Convenience flag for guards / UI.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});