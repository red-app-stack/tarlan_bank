/// Client-side resend throttle for verification emails.
///
/// Firebase applies its own server-side rate limit; this adds the same 60s
/// cooldown the old Node flow had, so the UI cannot spam "resend" locally.
/// Pure (injectable clock) so the arithmetic is unit-testable.
class EmailVerificationThrottle {
  EmailVerificationThrottle({
    this.interval = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration interval;
  final DateTime Function() _now;
  final Map<String, DateTime> _sentAt = {};

  Duration remaining(String email) {
    final sentAt = _sentAt[email.toLowerCase().trim()];
    if (sentAt == null) return Duration.zero;
    final elapsed = _now().difference(sentAt);
    if (elapsed >= interval) return Duration.zero;
    return interval - elapsed;
  }

  bool canSend(String email) => remaining(email) == Duration.zero;

  void recordSend(String email, {DateTime? at}) =>
      _sentAt[email.toLowerCase().trim()] = at ?? _now();

  /// Seed from persistent storage (SharedPreferences) on app restart.
  void seed(String email, DateTime sentAt) =>
      _sentAt[email.toLowerCase().trim()] = sentAt;

  void reset(String email) => _sentAt.remove(email.toLowerCase().trim());
}
