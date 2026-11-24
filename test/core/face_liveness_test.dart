import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/security/face_liveness.dart';
import 'package:tarlan_bank/core/security/face_verification_store.dart';
import 'package:tarlan_bank/core/services/key_value_store.dart';

class _Mem implements KeyValueStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String k) async => m[k];
  @override
  Future<void> write(String k, String v) async => m[k] = v;
  @override
  Future<void> delete(String k) async => m.remove(k);
}

FaceSample ok({double? yaw, double? l, double? r, double? smile}) => FaceSample(
  faceCount: 1,
  yaw: yaw ?? 0,
  leftEyeOpen: l ?? .9,
  rightEyeOpen: r ?? .9,
  smile: smile ?? .1,
);

void main() {
  test('framing hints and multiple faces', () {
    final e = LivenessEngine(random: Random(1));
    expect(e.update(const FaceSample.none()).hint, LivenessHint.noFace);
    expect(
      e.update(const FaceSample(faceCount: 2)).hint,
      LivenessHint.multipleFaces,
    );
    expect(
      e.update(const FaceSample(faceCount: 1, widthRatio: .1)).hint,
      LivenessHint.moveCloser,
    );
    expect(
      e.update(const FaceSample(faceCount: 1, centerX: .9)).hint,
      LivenessHint.centerFace,
    );
  });

  test('a static photo never passes', () {
    final e = LivenessEngine(random: Random(2));
    LivenessState s = e.update(ok());
    for (var i = 0; i < 500; i++) {
      s = e.update(ok());
    }
    expect(s.passed, isFalse);
    expect(s.hint, LivenessHint.challenge);
  });

  test('completing the queued challenges passes', () {
    final e = LivenessEngine(random: Random(3));
    var s = e.update(ok());
    for (var i = 0; i < 10; i++) {
      s = e.update(ok());
    }
    var guard = 0;
    while (!s.passed && guard++ < 10) {
      switch (s.challenge!) {
        case LivenessChallenge.blink:
          e.update(ok());
          e.update(ok(l: .1, r: .1));
          s = e.update(ok());
        case LivenessChallenge.smile:
          e.update(ok(smile: .05));
          s = e.update(ok(smile: .95));
        case LivenessChallenge.turnHead:
          e.update(ok(yaw: 30));
          s = e.update(ok(yaw: 2));
      }
    }
    expect(s.passed, isTrue);
  });

  test('leaving the frame mid-challenge restarts progress', () {
    final e = LivenessEngine(random: Random(4));
    for (var i = 0; i < 10; i++) {
      e.update(ok());
    }
    final s = e.update(const FaceSample(faceCount: 2));
    expect(s.completed, 0);
    expect(s.hint, LivenessHint.multipleFaces);
  });

  test('store is owned by uid', () async {
    final st = FaceVerificationStore(_Mem());
    expect(await st.isVerified('a'), isFalse);
    await st.markVerified('a', 'liveness');
    expect(await st.isVerified('a'), isTrue);
    expect(await st.isVerified('b'), isFalse);
  });
}
