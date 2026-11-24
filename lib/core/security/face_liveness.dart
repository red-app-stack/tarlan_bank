import 'dart:math';

/// Active-liveness state machine. Pure Dart — no Flutter or plugin deps, so
/// it is unit-testable by feeding [FaceSample]s.
///
/// Flow: stable, well-framed face -> N randomized challenges -> passed.
/// Losing the face, or seeing a second one, restarts the whole sequence.
///
/// NOTE: this is client-side *active* liveness. It raises the bar against
/// photos and simple replays, but it cannot stop a determined attacker with
/// a rooted device, a virtual camera or a deepfake stream. See README notes.
enum LivenessChallenge { blink, smile, turnHead }

enum LivenessHint {
  noFace,
  multipleFaces,
  moveCloser,
  moveFarther,
  centerFace,
  holdStill,
  challenge,
  passed,
}

/// One analysed camera frame, already normalised by the caller.
class FaceSample {
  const FaceSample({
    required this.faceCount,
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.widthRatio = 0.5,
    this.yaw,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smile,
  });

  const FaceSample.none() : this(faceCount: 0);

  final int faceCount;

  /// Face centre and width as a fraction of the (rotated) frame, 0..1.
  final double centerX;
  final double centerY;
  final double widthRatio;

  /// Head yaw in degrees; probabilities are 0..1 (null = unavailable).
  final double? yaw;
  final double? leftEyeOpen;
  final double? rightEyeOpen;
  final double? smile;
}

class LivenessState {
  const LivenessState({
    required this.hint,
    required this.completed,
    required this.total,
    this.challenge,
  });

  final LivenessHint hint;
  final LivenessChallenge? challenge;
  final int completed;
  final int total;

  bool get passed => hint == LivenessHint.passed;
  double get progress => total == 0 ? 0 : completed / total;
}

class LivenessEngine {
  LivenessEngine({Random? random, this.challengeCount = 2})
    : _random = random ?? Random.secure() {
    reset();
  }

  final Random _random;
  final int challengeCount;

  static const int _stableFramesNeeded = 8;
  static const int _lostFramesToReset = 12;
  static const double _maxOffsetX = 0.16;
  static const double _maxOffsetY = 0.20;
  static const double _minWidth = 0.28;
  static const double _maxWidth = 0.80;

  late List<LivenessChallenge> _queue;
  int _done = 0;
  int _stable = 0;
  int _lost = 0;
  bool _armed = false; // framing was stable at least once
  // Per-challenge sub-state.
  bool _eyesWereOpen = false;
  bool _eyesClosed = false;
  bool _turned = false;
  bool _neutralSmile = false;

  void reset() {
    final all = List<LivenessChallenge>.of(LivenessChallenge.values)
      ..shuffle(_random);
    _queue = all.take(challengeCount.clamp(1, all.length)).toList();
    _done = 0;
    _stable = 0;
    _lost = 0;
    _armed = false;
    _resetChallengeState();
  }

  void _resetChallengeState() {
    _eyesWereOpen = false;
    _eyesClosed = false;
    _turned = false;
    _neutralSmile = false;
  }

  LivenessState _state(LivenessHint hint) => LivenessState(
    hint: hint,
    challenge: _done < _queue.length ? _queue[_done] : null,
    completed: _done,
    total: _queue.length,
  );

  LivenessState update(FaceSample s) {
    if (_done >= _queue.length) return _state(LivenessHint.passed);

    if (s.faceCount == 0) {
      if (++_lost >= _lostFramesToReset) reset();
      return _state(LivenessHint.noFace);
    }
    if (s.faceCount > 1) {
      reset();
      return _state(LivenessHint.multipleFaces);
    }
    _lost = 0;

    final framing = _framingHint(s);
    if (framing != null) {
      // Out of frame during a challenge invalidates the attempt.
      if (_armed) reset();
      _stable = 0;
      return _state(framing);
    }

    if (!_armed) {
      if (++_stable < _stableFramesNeeded) {
        return _state(LivenessHint.holdStill);
      }
      _armed = true;
      _resetChallengeState();
    }

    if (_challengeSatisfied(_queue[_done], s)) {
      _done++;
      _resetChallengeState();
      if (_done >= _queue.length) return _state(LivenessHint.passed);
    }
    return _state(LivenessHint.challenge);
  }

  LivenessHint? _framingHint(FaceSample s) {
    if (s.widthRatio < _minWidth) return LivenessHint.moveCloser;
    if (s.widthRatio > _maxWidth) return LivenessHint.moveFarther;
    if ((s.centerX - 0.5).abs() > _maxOffsetX ||
        (s.centerY - 0.5).abs() > _maxOffsetY) {
      return LivenessHint.centerFace;
    }
    return null;
  }

  bool _challengeSatisfied(LivenessChallenge c, FaceSample s) {
    switch (c) {
      case LivenessChallenge.blink:
        final l = s.leftEyeOpen, r = s.rightEyeOpen;
        if (l == null || r == null) return false;
        final open = l > 0.7 && r > 0.7;
        final closed = l < 0.25 && r < 0.25;
        if (open && !_eyesClosed) _eyesWereOpen = true;
        if (_eyesWereOpen && closed) _eyesClosed = true;
        return _eyesClosed && open; // open -> closed -> open
      case LivenessChallenge.smile:
        final p = s.smile;
        if (p == null) return false;
        if (p < 0.2) _neutralSmile = true;
        return _neutralSmile && p > 0.8; // neutral first, then a real smile
      case LivenessChallenge.turnHead:
        final y = s.yaw;
        if (y == null) return false;
        if (y.abs() > 20) _turned = true;
        return _turned && y.abs() < 8; // turned away, then back to centre
    }
  }
}
