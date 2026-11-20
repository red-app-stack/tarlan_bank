import 'dart:async';

import 'package:tarlan_bank/core/errors/app_failure.dart';

import 'auth_repository.dart';
import 'auth_user.dart';

/// TEMPORARY scaffolding stub — always signed out, no backend wired yet.
///
/// Replace with `FirebaseAuthRepository` once the Firebase project is configured
/// (see MIGRATION_PLAN.md Week 1). Kept GetX-free so the new architecture stays
/// clean. Login/register throw [AuthFailure] rather than faking a session.
class StubAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    // Replay current state to each new subscriber (broadcast streams don't
    // buffer past events), then forward live updates.
    yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    throw const AuthFailure('Auth backend not configured yet');
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    throw const AuthFailure('Auth backend not configured yet');
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    throw const AuthFailure('Auth backend not configured yet');
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    throw const AuthFailure('Auth backend not configured yet');
  }

  @override
  Future<void> sendEmailVerification() async {
    throw const AuthFailure('Auth backend not configured yet');
  }

  @override
  Future<bool> refreshEmailVerification() async => false;

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {}

  void dispose() => _controller.close();
}
