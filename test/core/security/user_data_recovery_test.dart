import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/security/user_data_recovery.dart';
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
  test(
    'wipes account and PIN data but keeps biometric/one-time flags',
    () async {
      final kv = _MemoryStore();
      for (final key in [
        ...UserDataRecovery.keysToDelete,
        ...UserDataRecovery.keysToKeep,
      ]) {
        await kv.write(key, 'stored');
      }
      var cleared = 0;
      final recovery = UserDataRecovery(kv, onCleared: () => cleared++);

      await recovery();

      expect(cleared, 1);
      for (final key in UserDataRecovery.keysToDelete) {
        expect(kv.values.containsKey(key), isFalse, reason: key);
      }
      for (final key in UserDataRecovery.keysToKeep) {
        expect(kv.values[key], 'stored', reason: key);
      }
    },
  );
}
