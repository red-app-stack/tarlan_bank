/// Pure inactivity clock for the PIN gate. No Flutter, Riverpod or plugin deps.
///
/// The tracker never runs a background timer. It records the wall-clock time
/// of the last user interaction and answers "has the window elapsed?" when
/// asked. That keeps it correct across a frozen/backgrounded isolate: wall
/// clock keeps advancing while the app is suspended, so the first check after
/// resume sees the real gap.
class InactivityTracker {
  InactivityTracker({
    this.timeout = defaultInactivityTimeout,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Time without interaction before the PIN gate re-locks.
  ///
  /// Kept here, not scattered across UI code, so product can change it in one
  /// place and tests can inject shorter windows.
  static const defaultInactivityTimeout = Duration(minutes: 2);

  final Duration timeout;
  final DateTime Function() _now;
  DateTime? _lastActivity;

  /// Start (or restart) the window. Called on user interaction and whenever
  /// the gate is freshly unlocked.
  void recordActivity() => _lastActivity = _now();

  /// True once [timeout] has passed with no interaction.
  ///
  /// A clock moved backwards by the user must never lock them out, so a
  /// negative elapsed duration is treated as "not timed out".
  bool get isTimedOut {
    final last = _lastActivity;
    if (last == null) return false;
    return _now().difference(last) >= timeout;
  }
}

/// Convenience alias used by the guard and tests.
const Duration defaultInactivityTimeout =
    InactivityTracker.defaultInactivityTimeout;
