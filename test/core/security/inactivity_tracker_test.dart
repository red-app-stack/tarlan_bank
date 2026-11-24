import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/security/inactivity_tracker.dart';

void main() {
  group('InactivityTracker', () {
    final start = DateTime.utc(2026, 11, 24, 10, 0);
    late DateTime now;
    late InactivityTracker tracker;

    setUp(() {
      now = start;
      tracker = InactivityTracker(
        timeout: const Duration(minutes: 2),
        now: () => now,
      );
    });

    void advance(Duration by) => now = now.add(by);

    test('does not time out before the first interaction', () {
      advance(const Duration(hours: 5));
      expect(tracker.isTimedOut, isFalse);
    });

    test('stays open inside the window and closes exactly at the boundary', () {
      tracker.recordActivity();
      advance(const Duration(minutes: 1, seconds: 59));
      expect(tracker.isTimedOut, isFalse);
      advance(const Duration(seconds: 1));
      expect(tracker.isTimedOut, isTrue);
    });

    test('any interaction restarts the full window', () {
      tracker.recordActivity();
      advance(const Duration(minutes: 1, seconds: 50));
      expect(tracker.isTimedOut, isFalse);
      tracker.recordActivity();
      advance(const Duration(minutes: 1, seconds: 50));
      expect(tracker.isTimedOut, isFalse);
      advance(const Duration(seconds: 10));
      expect(tracker.isTimedOut, isTrue);
    });

    test('a long frozen/background gap is detected on the next check', () {
      tracker.recordActivity();
      // No timer fires during the gap; the first check after resume still
      // sees the whole elapsed wall-clock duration.
      now = start.add(const Duration(hours: 3));
      expect(tracker.isTimedOut, isTrue);
    });

    test('a clock moved backwards never locks the user out', () {
      tracker.recordActivity();
      now = start.subtract(const Duration(minutes: 30));
      expect(tracker.isTimedOut, isFalse);
    });

    test('default timeout is a non-zero product constant', () {
      expect(defaultInactivityTimeout, const Duration(minutes: 2));
      expect(InactivityTracker().timeout, defaultInactivityTimeout);
    });
  });
}
