import 'dart:convert';

import 'package:tarlan_bank/core/services/key_value_store.dart';

/// Device-local record that this Firebase uid passed face verification on THIS
/// device. Owned by the uid, like the access-code owner marker: another
/// account signing in here never inherits it, and a new device has none —
/// which is exactly the "new-device login" trigger.
///
/// Holds no biometric data: only uid, method and a timestamp.
class FaceVerificationStore {
  FaceVerificationStore(this._store);

  static const key = 'face_verified_v1';
  static const deviceIdKey = 'face_device_id';

  final KeyValueStore _store;

  Future<bool> isVerified(String uid) async {
    final raw = await _store.read(key);
    if (raw == null) return false;
    try {
      final d = jsonDecode(raw);
      return d is Map<String, dynamic> && d['owner'] == uid;
    } catch (_) {
      return false;
    }
  }

  Future<void> markVerified(String uid, String method) => _store.write(
    key,
    jsonEncode({
      'owner': uid,
      'method': method,
      'at': DateTime.now().toUtc().toIso8601String(),
    }),
  );

  Future<void> clear() => _store.delete(key);

  /// Random per-install id (not a hardware id) used to tell devices apart in
  /// the audit record.
  Future<String> deviceId(String Function() generate) async {
    final existing = await _store.read(deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = generate();
    await _store.write(deviceIdKey, id);
    return id;
  }
}
