import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/auth/data/email_verification_throttle.dart';

void main() {
  test('first send is allowed, then a 60s cooldown applies', () {
    var now = DateTime.utc(2026, 11, 20, 12);
    final throttle = EmailVerificationThrottle(now: () => now);

    expect(throttle.canSend('User@Example.com'), isTrue);
    throttle.recordSend('USER@example.com');
    expect(throttle.canSend('user@example.com'), isFalse);
    expect(throttle.remaining('user@example.com'), const Duration(seconds: 60));

    now = now.add(const Duration(seconds: 30));
    expect(throttle.remaining('user@example.com'), const Duration(seconds: 30));

    now = now.add(const Duration(seconds: 31));
    expect(throttle.canSend('user@example.com'), isTrue);
  });

  test('cooldowns are per address and can be seeded from storage', () {
    var now = DateTime.utc(2026, 11, 20, 12);
    final throttle = EmailVerificationThrottle(now: () => now);
    throttle.recordSend('a@example.com');

    expect(throttle.canSend('b@example.com'), isTrue);
    throttle.seed('b@example.com', now.subtract(const Duration(seconds: 10)));
    expect(throttle.remaining('b@example.com'), const Duration(seconds: 50));

    throttle.reset('b@example.com');
    expect(throttle.canSend('b@example.com'), isTrue);
  });
}
