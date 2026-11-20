import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('sealed hierarchy is exhaustively switchable', () {
      const failures = <AppFailure>[
        NetworkFailure(),
        ServerFailure(500),
        AuthFailure(),
        ValidationFailure('Insufficient balance'),
        NotFoundFailure(),
        UnknownFailure(),
      ];

      final labels = failures
          .map((f) => switch (f) {
                NetworkFailure() => 'network',
                ServerFailure() => 'server',
                AuthFailure() => 'auth',
                ValidationFailure() => 'validation',
                NotFoundFailure() => 'notFound',
                UnknownFailure() => 'unknown',
              })
          .toList();

      expect(labels, [
        'network',
        'server',
        'auth',
        'validation',
        'notFound',
        'unknown',
      ]);
    });

    test('ServerFailure carries status code and default message', () {
      const f = ServerFailure(404);
      expect(f.statusCode, 404);
      expect(f.message, contains('404'));
    });

    test('cause is preserved for logging but message stays UI-safe', () {
      final cause = Exception('raw stack detail');
      final f = NetworkFailure('Network unavailable', cause);
      expect(f.cause, same(cause));
      expect(f.message, 'Network unavailable');
    });

    test('ValidationFailure supports custom message (balance checks)', () {
      const f = ValidationFailure('Insufficient balance');
      expect(f.message, 'Insufficient balance');
    });
  });
}
