import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import 'app_failure.dart';

/// Maps Firebase SDK exceptions (Auth + Firestore) to sealed [AppFailure]s.
///
/// Pure function (no plugin calls) so it is unit-testable with constructed
/// exceptions. Repositories call this in `catch`; nothing raw ever reaches UI.
AppFailure mapFirebaseError(Object error) {
  if (error is fb.FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return NetworkFailure('Network unavailable', error);
      case 'invalid-email':
        return const ValidationFailure('Invalid email address');
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        // Deliberately identical: do not leak which field was wrong.
        return AuthFailure('Invalid email or password', error);
      case 'email-already-in-use':
        return AuthFailure('Email already registered', error);
      case 'weak-password':
        return ValidationFailure(
            'Password is too weak (minimum 6 characters)', error);
      case 'too-many-requests':
        return AuthFailure('Too many attempts — try again later', error);
      case 'requires-recent-login':
        return AuthFailure('Please sign in again to confirm this action', error);
      case 'user-disabled':
        return AuthFailure('This account has been disabled', error);
      case 'operation-not-allowed':
        return const ServerFailure(501, 'Sign-in method not enabled');
      default:
        return AuthFailure(error.message ?? 'Authentication failed', error);
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkFailure('Network unavailable', error);
      case 'permission-denied':
        return AuthFailure('Access denied', error);
      case 'not-found':
        return NotFoundFailure('Not found', error);
      case 'already-exists':
        return ValidationFailure('Already exists', error);
      default:
        return UnknownFailure(error.message ?? 'Unexpected error', error);
    }
  }
  if (error is AppFailure) return error;
  return UnknownFailure('Unexpected error', error);
}
