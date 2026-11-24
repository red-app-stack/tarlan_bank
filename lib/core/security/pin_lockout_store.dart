import 'dart:convert';

import 'package:tarlan_bank/core/security/pin_lockout.dart';
import 'package:tarlan_bank/core/services/key_value_store.dart';

/// Persists the failed-code streak and the absolute lockout release time.
///
/// Writes happen only when a code fails or the streak is cleared — never from
/// the 1-second countdown. Restarting (or force-closing during a lockout)
/// therefore cannot shorten or reset it: the remaining time is derived from
/// the stored release timestamp against the current wall clock.
class PinLockoutStore {
  PinLockoutStore(this._store, this._uid);

  static const key = 'pin_lockout_v1';

  final KeyValueStore _store;
  final String _uid;

  Future<void> save(PinLockout lockout) => _store.write(
    key,
    jsonEncode(<String, Object?>{
      'owner': _uid,
      'failures': lockout.failures,
      'lockouts': lockout.lockouts,
      'release': lockout.releaseMicroseconds,
    }),
  );

  /// A snapshot owned by a different uid is ignored: a new account on this
  /// device must not inherit someone else's lockout.
  Future<void> restore(PinLockout lockout) async {
    final raw = await _store.read(key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['owner'] != _uid) return;
      final failures = decoded['failures'];
      final release = decoded['release'];
      if (failures is! int) return;
      lockout.restore(
        failures: failures,
        // Old v1 snapshots have no tier field; one served lockout is the
        // safest inference so the next failure escalates instead of looping.
        lockouts: decoded['lockouts'] is int
            ? decoded['lockouts'] as int
            : (failures >= attemptsPerLockoutStep ? 1 : 0),
        releaseMicroseconds: release is int ? release : null,
      );
    } catch (_) {
      // Corrupt or foreign payload: start clean instead of locking anyone out.
    }
  }

  Future<void> clear() => _store.delete(key);
}
