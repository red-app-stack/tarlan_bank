/// Failed-PIN lockout policy. Pure Dart — no Flutter or plugin deps.
///
/// The first lockout starts after [attemptsPerLockoutStep] bad codes. Every
/// lockout after that uses the next duration in the ladder, so the moment one
/// lockout expires the next bad code moves straight to the next tier. Steps
/// are rounded to human-friendly durations (30s, 1m, 2m, 5m, 10m, 15m, 30m,
/// 1h) rather than raw 2^n: 3840s reads worse than "1 hour" and is no safer.
/// Past the table it doubles each step, capped at 24h so nobody is locked out
/// indefinitely.
const int attemptsPerLockoutStep = 5;

const Duration maxPinLockout = Duration(hours: 24);

const List<Duration> pinLockoutSteps = [
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(minutes: 2),
  Duration(minutes: 5),
  Duration(minutes: 10),
  Duration(minutes: 15),
  Duration(minutes: 30),
  Duration(hours: 1),
];

/// Duration of lockout number [step] (0-based): 30s, 60s, 120s, ... capped.
Duration pinLockoutDurationForStep(int step) {
  if (step < 0) return Duration.zero;
  if (step < pinLockoutSteps.length) return pinLockoutSteps[step];
  var duration = pinLockoutSteps.last;
  for (var i = pinLockoutSteps.length; i <= step; i++) {
    duration = duration * 2;
    if (duration >= maxPinLockout) return maxPinLockout;
  }
  return duration;
}

/// Mutable lockout state with an injectable clock so UI and tests can ask
/// "is it over yet?" without owning a timer. Time is wall clock: a suspended
/// isolate cannot fire timers, but the clock keeps advancing, so the first
/// check after resume sees the real remaining time.
class PinLockout {
  PinLockout({DateTime Function()? now, Duration Function(int)? durationFor})
    : _now = now ?? DateTime.now,
      _durationFor = durationFor ?? pinLockoutDurationForStep;

  final DateTime Function() _now;
  final Duration Function(int) _durationFor;

  int _failures = 0;
  int _lockouts = 0;
  DateTime? _lockedUntil;

  int get failures => _failures;

  /// How many lockouts have been started — this drives the escalation tier.
  int get lockouts => _lockouts;

  bool isLockedAt(DateTime instant) =>
      _lockedUntil != null && instant.isBefore(_lockedUntil!);

  Duration remainingAt(DateTime instant) =>
      isLockedAt(instant) ? _lockedUntil!.difference(instant) : Duration.zero;

  bool get isLocked => isLockedAt(_now());

  Duration get remaining => remainingAt(_now());

  /// Absolute release instant, persisted so a restart can reconstruct the
  /// remaining time without writing to storage every tick.
  int? get releaseMicroseconds => _lockedUntil?.microsecondsSinceEpoch;

  /// Restores a persisted streak. An expired release is kept so the next bad
  /// code advances to the next tier; `isLocked` already reports false for it.
  void restore({
    required int failures,
    int lockouts = 0,
    int? releaseMicroseconds,
  }) {
    _failures = failures < 0 ? 0 : failures;
    _lockouts = lockouts < 0 ? 0 : lockouts;
    _lockedUntil = releaseMicroseconds == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(
            releaseMicroseconds,
            isUtc: false,
          );
  }

  /// Counts one bad code. The first [attemptsPerLockoutStep] failures open
  /// the 30s lockout; after any lockout expires, the very next failure opens
  /// the next tier.
  void registerFailure() {
    _failures++;
    if (isLocked) return;
    if (_lockouts == 0 && _failures < attemptsPerLockoutStep) return;
    _lockedUntil = _now().add(_durationFor(_lockouts));
    _lockouts++;
  }

  /// A correct code or a verified reset clears the streak and the timer.
  void reset() {
    _failures = 0;
    _lockouts = 0;
    _lockedUntil = null;
  }
}
