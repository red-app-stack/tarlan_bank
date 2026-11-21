import 'dart:math';

class RecipientLookupGuard {
  RecipientLookupGuard({required this.maxFailures, required this.cooldown});

  final int maxFailures;
  final Duration cooldown;
  int _failures = 0;
  DateTime? _blockedUntil;

  bool get isBlocked {
    final until = _blockedUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _blockedUntil = null;
      _failures = 0;
      return false;
    }
    return true;
  }

  void registerFailure() {
    _failures++;
    if (_failures >= max(1, maxFailures)) {
      _blockedUntil = DateTime.now().add(cooldown);
    }
  }

  void registerSuccess() {
    _failures = 0;
    _blockedUntil = null;
  }
}
