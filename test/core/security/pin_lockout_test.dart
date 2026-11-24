import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/security/pin_lockout.dart';

void main() {
  group('pinLockoutDurationForStep ladder', () {
    test('uses the chosen rounded durations, then doubles to a 24h cap', () {
      const expected = <int, Duration>{
        0: Duration(seconds: 30),
        1: Duration(seconds: 60),
        2: Duration(minutes: 2),
        3: Duration(minutes: 5),
        4: Duration(minutes: 10),
        5: Duration(minutes: 15),
        6: Duration(minutes: 30),
        7: Duration(hours: 1),
        8: Duration(hours: 2),
        9: Duration(hours: 4),
        10: Duration(hours: 8),
        11: Duration(hours: 16),
        12: Duration(hours: 24),
        99: Duration(hours: 24),
      };
      expected.forEach((step, duration) {
        expect(pinLockoutDurationForStep(step), duration, reason: '$step');
      });
      expect(pinLockoutDurationForStep(-1), Duration.zero);
    });
  });

  group('PinLockout', () {
    final start = DateTime.utc(2026, 11, 24, 12, 0);
    late DateTime now;
    late PinLockout lockout;

    setUp(() {
      now = start;
      lockout = PinLockout(now: () => now);
    });

    void failTimes(int count) {
      for (var i = 0; i < count; i++) {
        lockout.registerFailure();
      }
    }

    test('stays open for the first four failures', () {
      failTimes(4);
      expect(lockout.isLocked, isFalse);
      expect(lockout.remaining, Duration.zero);
    });

    test('locks for 30s on the fifth failure and counts down', () {
      failTimes(5);
      expect(lockout.isLocked, isTrue);
      expect(lockout.remaining, const Duration(seconds: 30));
      now = now.add(const Duration(seconds: 12));
      expect(lockout.remaining, const Duration(seconds: 18));
      now = now.add(const Duration(seconds: 18));
      expect(lockout.isLocked, isFalse);
      expect(lockout.remaining, Duration.zero);
    });

    test('next failure after a served lockout escalates to 60s, then 120s', () {
      failTimes(5);
      expect(lockout.remaining, const Duration(seconds: 30));

      now = now.add(const Duration(seconds: 31));
      expect(lockout.isLocked, isFalse);
      lockout.registerFailure();
      expect(lockout.remaining, const Duration(seconds: 60));
      expect(lockout.lockouts, 2);

      now = now.add(const Duration(minutes: 1, seconds: 1));
      lockout.registerFailure();
      expect(lockout.remaining, const Duration(minutes: 2));
      expect(lockout.lockouts, 3);
    });

    test('failures during an active lockout do not add extra tiers', () {
      failTimes(5);
      expect(lockout.lockouts, 1);
      lockout.registerFailure();
      lockout.registerFailure();
      expect(lockout.lockouts, 1);
      expect(lockout.remaining, const Duration(seconds: 30));
    });

    test('a correct code clears streak, tier and timer', () {
      failTimes(7);
      expect(lockout.isLocked, isTrue);
      lockout.reset();
      expect(lockout.isLocked, isFalse);
      expect(lockout.failures, 0);
      expect(lockout.lockouts, 0);
      lockout.registerFailure();
      expect(lockout.isLocked, isFalse);
    });
  });
}
