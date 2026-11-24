import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/security/pin_lockout.dart';
import 'package:tarlan_bank/core/security/pin_lockout_store.dart';
import 'package:tarlan_bank/core/services/key_value_store.dart';

class _MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  final start = DateTime.utc(2026, 11, 24, 14, 0);
  late _MemoryStore kv;
  late PinLockoutStore store;

  setUp(() {
    kv = _MemoryStore();
    store = PinLockoutStore(kv, 'uid-1');
  });

  PinLockout lockoutAt(DateTime Function() now) => PinLockout(now: now);

  test(
    'saves only failures and an absolute release, no per-tick writes',
    () async {
      var now = start;
      final lockout = lockoutAt(() => now);
      for (var i = 0; i < 5; i++) {
        lockout.registerFailure();
      }
      final writesBefore = kv.values.length;
      await store.save(lockout);
      expect(kv.values.length, writesBefore + 1);

      final map =
          jsonDecode(kv.values[PinLockoutStore.key]!) as Map<String, dynamic>;
      expect(map['owner'], 'uid-1');
      expect(map['failures'], 5);
      expect(map['lockouts'], 1);
      expect(
        map['release'],
        start.add(const Duration(seconds: 30)).microsecondsSinceEpoch,
      );
    },
  );

  test(
    'force-closing during lockout preserves the exact remaining time',
    () async {
      var now = start;
      final before = lockoutAt(() => now);
      for (var i = 0; i < 5; i++) {
        before.registerFailure();
      }
      await store.save(before);

      // App killed; 12s pass while nothing is running or writing.
      now = start.add(const Duration(seconds: 12));
      final after = lockoutAt(() => now);
      await store.restore(after);

      expect(after.isLocked, isTrue);
      expect(after.remaining, const Duration(seconds: 18));
      expect(after.failures, 5);
      expect(after.lockouts, 1);
    },
  );

  test(
    'an expired snapshot unlocks but keeps the streak for escalation',
    () async {
      var now = start;
      final before = lockoutAt(() => now);
      for (var i = 0; i < 5; i++) {
        before.registerFailure();
      }
      await store.save(before);

      now = start.add(const Duration(seconds: 31));
      final after = lockoutAt(() => now);
      await store.restore(after);
      expect(after.isLocked, isFalse);
      expect(after.failures, 5);
      expect(after.lockouts, 1);

      after.registerFailure();
      expect(after.remaining, const Duration(seconds: 60));
    },
  );

  test('a persisted tier keeps escalating after another restart', () async {
    var now = start;
    final first = lockoutAt(() => now);
    for (var i = 0; i < 5; i++) {
      first.registerFailure();
    }
    now = start.add(const Duration(seconds: 31));
    first.registerFailure(); // 60s, tier 2
    await store.save(first);

    final second = lockoutAt(() => now);
    await store.restore(second);
    expect(second.lockouts, 2);
    expect(second.remaining, const Duration(seconds: 60));

    now = now.add(const Duration(minutes: 1, seconds: 1));
    second.registerFailure();
    expect(second.remaining, const Duration(minutes: 2));
  });

  test('a different uid cannot inherit the lockout', () async {
    var now = start;
    final before = lockoutAt(() => now);
    for (var i = 0; i < 5; i++) {
      before.registerFailure();
    }
    await store.save(before);

    final other = lockoutAt(() => now);
    await PinLockoutStore(kv, 'uid-2').restore(other);
    expect(other.failures, 0);
    expect(other.isLocked, isFalse);
  });

  test('corrupt payload is ignored instead of locking anyone out', () async {
    await kv.write(PinLockoutStore.key, '{not json');
    final restored = lockoutAt(() => start);
    await store.restore(restored);
    expect(restored.failures, 0);
    expect(restored.isLocked, isFalse);
  });

  test('clear removes the persisted streak', () async {
    final lockout = lockoutAt(() => start);
    for (var i = 0; i < 5; i++) {
      lockout.registerFailure();
    }
    await store.save(lockout);
    await store.clear();
    expect(kv.values.containsKey(PinLockoutStore.key), isFalse);
  });
}
