import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/auth/data/stub_auth_repository.dart';

void main() {
  group('StubAuthRepository (scaffolding)', () {
    test('starts signed out', () async {
      final repo = StubAuthRepository();
      addTearDown(repo.dispose);

      expect(repo.currentUser, isNull);
      expect(await repo.authStateChanges().first, isNull);
    });

    test('login throws AuthFailure rather than faking a session', () {
      final repo = StubAuthRepository();
      addTearDown(repo.dispose);

      expect(
        () => repo.login(email: 'a@b.c', password: 'x'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('register throws AuthFailure', () {
      final repo = StubAuthRepository();
      addTearDown(repo.dispose);

      expect(
        () => repo.register(
          email: 'a@b.c',
          password: 'x',
          fullName: 'Test',
          phoneNumber: '+70000000000',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
