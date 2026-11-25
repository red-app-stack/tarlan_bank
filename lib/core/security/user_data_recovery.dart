import 'package:tarlan_bank/core/services/key_value_store.dart';

/// Selective local wipe for corrupt user data. Biometric flags and one-time
/// show-cases (biometrics/face prompts, theme) survive so a returning user is
/// not re-onboarded; the PIN and every account-bound record do not.
class UserDataRecovery {
  UserDataRecovery(this._store, {this.onCleared});

  final KeyValueStore _store;
  final void Function()? onCleared;

  /// user_data, access code + owner, PIN streak and local favourites.
  static const List<String> keysToDelete = [
    'user_data',
    'access_code',
    'access_code_owner',
    'pin_lockout_v1',
    'favorite_transfers',
  ];

  /// Deliberately kept: user_settings (biometrics already enabled),
  /// face_verified_v1 and face_device_id.
  static const List<String> keysToKeep = [
    'user_settings',
    'face_verified_v1',
    'face_device_id',
  ];

  Future<void> call() async {
    for (final key in keysToDelete) {
      await _store.delete(key);
    }
    onCleared?.call();
  }
}
