import 'package:shared_preferences/shared_preferences.dart';

import 'email_verification_throttle.dart';

/// Persists the last verification-email send time per address, so the 60s
/// cooldown survives app restarts. Firebase's server-side limit is the real
/// protection; this only stops local resend spam.
class EmailVerificationCooldownStore {
  EmailVerificationCooldownStore(
    this._prefs, {
    DateTime Function()? now,
    Duration interval = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now,
       _throttle = EmailVerificationThrottle(interval: interval, now: now);

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final EmailVerificationThrottle _throttle;

  static const _prefix = 'verification_email_sent_';

  String _key(String email) => _prefix + email.toLowerCase().trim();

  /// Milliseconds left before another email may be requested.
  Future<Duration> remaining(String email) async {
    final millis = _prefs.getInt(_key(email));
    if (millis != null) {
      _throttle.seed(email, DateTime.fromMillisecondsSinceEpoch(millis));
    }
    return _throttle.remaining(email);
  }

  Future<void> recordSend(String email) async {
    final at = _now();
    await _prefs.setInt(_key(email), at.millisecondsSinceEpoch);
    _throttle.recordSend(email, at: at);
  }
}
