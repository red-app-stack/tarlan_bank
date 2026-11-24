import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';

void main() {
  group('mapFirebaseError — FirebaseAuthException', () {
    test('network failure maps to NetworkFailure', () {
      final e = fb.FirebaseAuthException(code: 'network-request-failed');
      expect(mapFirebaseError(e), isA<NetworkFailure>());
    });

    test('bad credentials are indistinguishable (no field leaking)', () {
      for (final code in [
        'wrong-password',
        'user-not-found',
        'invalid-credential',
      ]) {
        final f = mapFirebaseError(fb.FirebaseAuthException(code: code));
        expect(f, isA<AuthFailure>());
        expect(f.message, 'Invalid email or password');
      }
    });

    test('email-already-in-use maps to AuthFailure', () {
      final f = mapFirebaseError(
        fb.FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(f, isA<AuthFailure>());
      expect(f.message, 'Email already registered');
    });

    test('weak-password maps to ValidationFailure', () {
      expect(
        mapFirebaseError(fb.FirebaseAuthException(code: 'weak-password')),
        isA<ValidationFailure>(),
      );
    });

    test('requires-recent-login maps to AuthFailure with re-auth hint', () {
      final f = mapFirebaseError(
        fb.FirebaseAuthException(code: 'requires-recent-login'),
      );
      expect(f, isA<AuthFailure>());
      expect(f.message, contains('sign in again'));
    });

    test('Google / provider-linking failures are typed and UI-safe', () {
      final cancelled = mapFirebaseError(
        fb.FirebaseAuthException(code: 'popup-closed-by-user'),
      );
      expect(cancelled, isA<AuthFailure>());
      expect(cancelled.message, 'Sign-in was cancelled');

      final linked = mapFirebaseError(
        fb.FirebaseAuthException(
          code: 'account-exists-with-different-credential',
        ),
      );
      expect(linked, isA<AuthFailure>());
      expect(linked.message, contains('another sign-in method'));

      final domain = mapFirebaseError(
        fb.FirebaseAuthException(code: 'unauthorized-domain'),
      );
      expect(domain, isA<ServerFailure>());
      expect((domain as ServerFailure).statusCode, 403);
    });

    test('GoogleSignInException (7.x) maps to typed UI-safe failures', () {
      const cancelled = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'user backed out',
      );
      final f = mapFirebaseError(cancelled);
      expect(f, isA<AuthFailure>());
      expect(f.message, 'Sign-in was cancelled');
      expect(f.message, isNot(contains('user backed out')));

      const misconfigured = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      );
      final s = mapFirebaseError(misconfigured);
      expect(s, isA<ServerFailure>());
      expect((s as ServerFailure).statusCode, 503);
    });

    test('unknown code falls back to AuthFailure, keeps cause', () {
      final e = fb.FirebaseAuthException(code: 'something-new', message: 'raw');
      final f = mapFirebaseError(e);
      expect(f, isA<AuthFailure>());
      expect(f.cause, same(e));
    });
  });

  group('mapFirebaseError — FirebaseException (Firestore)', () {
    test('unavailable maps to NetworkFailure', () {
      final e = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      expect(mapFirebaseError(e), isA<NetworkFailure>());
    });

    test('permission-denied maps to AuthFailure', () {
      final e = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(mapFirebaseError(e), isA<AuthFailure>());
    });

    test('not-found maps to NotFoundFailure', () {
      final e = FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
      expect(mapFirebaseError(e), isA<NotFoundFailure>());
    });
  });

  group('mapFirebaseError — passthrough', () {
    test('AppFailure passes through unchanged', () {
      const f = ValidationFailure('already typed');
      expect(mapFirebaseError(f), same(f));
    });

    test('arbitrary error maps to UnknownFailure with cause', () {
      final e = StateError('boom');
      final f = mapFirebaseError(e);
      expect(f, isA<UnknownFailure>());
      expect(f.cause, same(e));
    });
  });

  group('deleteReauthHint', () {
    test('detects the raw Firebase code', () {
      expect(
        deleteReauthHint(
          fb.FirebaseAuthException(code: 'requires-recent-login'),
        ),
        isTrue,
      );
    });

    test('detects it through a mapped AppFailure cause', () {
      final raw = fb.FirebaseAuthException(code: 'requires-recent-login');
      expect(mapFirebaseError(raw), isA<AuthFailure>());
      expect(deleteReauthHint(mapFirebaseError(raw)), isTrue);
    });

    test('does not fire for unrelated failures', () {
      expect(deleteReauthHint(StateError('boom')), isFalse);
      expect(
        deleteReauthHint(
          mapFirebaseError(fb.FirebaseAuthException(code: 'wrong-password')),
        ),
        isFalse,
      );
    });
  });
}
