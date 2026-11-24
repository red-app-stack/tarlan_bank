import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/access_policy.dart' show AccessLevel;
import 'package:tarlan_bank/core/router/pin_gate.dart' show PinGateStatus;
import 'package:tarlan_bank/core/security/face_verification_store.dart';
import 'package:tarlan_bank/features/auth/data/auth_user.dart';
import 'package:tarlan_bank/features/auth/data/face_verification_repository.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/auth/providers/pin_gate_provider.dart';

/// Face verification is a *feature* gate like the PIN gate: home/menu/rates
/// stay usable, protected features and the login/PIN-creation flow challenge.
enum FaceGateStatus { checking, notRequired, required, verified }

class FaceGateState {
  const FaceGateState(
    this.status, {
    this.pinFallback = false,
    this.scanAfterPin = false,
  });

  final FaceGateStatus status;

  /// User chose "use access code instead": the PIN screen is allowed through
  /// and a successful unlock counts as verification.
  final bool pinFallback;

  /// One-shot: PIN was just created/confirmed on this device, so the scan
  /// should run before the user is allowed back into guest screens.
  final bool scanAfterPin;
}

bool faceRequired(AccessLevel authLevel, FaceGateStatus status) =>
    authLevel == AccessLevel.full &&
    (status == FaceGateStatus.required || status == FaceGateStatus.checking);

final faceVerificationStoreProvider = Provider<FaceVerificationStore>(
  (ref) => FaceVerificationStore(ref.watch(secureStoreProvider)),
);

final faceVerificationRepositoryProvider = Provider<FaceVerificationRepository>(
  (ref) => FaceVerificationRepository(),
);

final faceGateProvider = NotifierProvider<FaceGateNotifier, FaceGateState>(
  FaceGateNotifier.new,
);

class FaceGateNotifier extends Notifier<FaceGateState> {
  String? _uid;

  @override
  FaceGateState build() {
    ref.listen(authStateProvider, (previous, next) {
      if (_identity(previous?.value) != _identity(next.value)) {
        _check(next.value);
      }
    });
    ref.listen(pinGateProvider, (previous, next) {
      if (next.status != PinGateStatus.unlocked ||
          previous?.status == PinGateStatus.unlocked) {
        return;
      }
      if (state.status != FaceGateStatus.required) return;
      if (state.pinFallback) {
        markVerified(method: 'pin');
        return;
      }
      // PIN established identity. Now the face check proves presence.
      state = FaceGateState(FaceGateStatus.required, scanAfterPin: true);
    });
    _check(ref.read(authStateProvider).value);
    return const FaceGateState(FaceGateStatus.checking);
  }

  String? _identity(AuthUser? u) =>
      u == null ? null : '${u.isAnonymous ? 'guest' : 'full'}:${u.uid}';

  Future<void> _check(AuthUser? user) async {
    if (user == null || user.isAnonymous) {
      _uid = null;
      state = const FaceGateState(FaceGateStatus.notRequired);
      return;
    }
    _uid = user.uid;
    state = const FaceGateState(FaceGateStatus.checking);
    try {
      final ok = await ref
          .read(faceVerificationStoreProvider)
          .isVerified(user.uid);
      if (!ref.mounted || _uid != user.uid) return;
      state = FaceGateState(
        ok ? FaceGateStatus.verified : FaceGateStatus.required,
      );
    } catch (_) {
      // Fail closed.
      if (ref.mounted) state = const FaceGateState(FaceGateStatus.required);
    }
  }

  void setPinFallback(bool value) => state = FaceGateState(
    state.status,
    pinFallback: value,
    scanAfterPin: false,
  );

  /// The user dismissed the scan. Home stays usable as a guest screen; a
  /// protected feature will challenge again.
  void dismissPending() => state = FaceGateState(
    state.status,
    pinFallback: state.pinFallback,
    scanAfterPin: false,
  );

  /// Persists the local record, opens the gate, then audits to Firestore
  /// best-effort (a flaky network must not undo a completed scan).
  Future<void> markVerified({
    required String method,
    int challenges = 0,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final store = ref.read(faceVerificationStoreProvider);
    await store.markVerified(uid, method);
    if (!ref.mounted) return;
    state = const FaceGateState(FaceGateStatus.verified);
    try {
      final id = await store.deviceId(() => const Uuid().v4());
      await ref
          .read(faceVerificationRepositoryProvider)
          .record(
            uid: uid,
            status: 'passed',
            method: method,
            deviceId: id,
            challenges: challenges,
          );
    } catch (_) {}
  }

  /// Manual/support path: file a review request. Throws on failure so the UI
  /// can say so. Does NOT open the gate — access stays limited until approval.
  Future<void> requestManualReview() async {
    final uid = _uid;
    if (uid == null) return;
    final store = ref.read(faceVerificationStoreProvider);
    final id = await store.deviceId(() => const Uuid().v4());
    await ref
        .read(faceVerificationRepositoryProvider)
        .record(
          uid: uid,
          status: 'manual_requested',
          method: 'support',
          deviceId: id,
        );
  }
}
