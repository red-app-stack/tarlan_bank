import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart';

import '../data/auth_user.dart';

import 'auth_providers.dart';

/// Process-local PIN gate. It starts closed on every cold start and is opened
/// only by the access-code screen (PIN, creation or biometrics). Only a change
/// of Firebase *session identity* re-closes it: ordinary auth stream events
/// for the same uid (e.g. email verification) must not eject an unlocked user.
final pinGateProvider = NotifierProvider<PinGateNotifier, PinGateState>(
  PinGateNotifier.new,
);

class PinGateNotifier extends Notifier<PinGateState> {
  @override
  PinGateState build() {
    ref.listen(authStateProvider, (previous, next) {
      if (_identity(previous?.value) != _identity(next.value)) {
        _checkCode(next.value);
      }
    });
    _checkCode(ref.read(authStateProvider).value);
    return const PinGateState(PinGateStatus.checking);
  }

  String? _identity(AuthUser? user) => user == null
      ? null
      : '${user.isAnonymous ? 'guest' : 'full'}:${user.uid}';

  Future<void> _checkCode([AuthUser? user]) async {
    try {
      final verification = ref.read(verificationServiceProvider);
      final signedIn = user ?? ref.read(authStateProvider).value;
      final fullUid = signedIn != null && !signedIn.isAnonymous
          ? signedIn.uid
          : null;
      if (fullUid != null) {
        final owner = await verification.accessCodeOwnerUid();
        if (!ref.mounted) return;
        if (shouldResetCodeForLogin(ownerUid: owner, fullUserUid: fullUid)) {
          // First full login on this device for this uid: a leftover code
          // belongs to another account and must never be reused.
          await verification.resetCodeForUser(fullUid);
          if (!ref.mounted) return;
          state = const PinGateState(PinGateStatus.needsSetup);
          return;
        }
      }
      final exists = await verification.accessCodeExists();
      if (!ref.mounted) return;
      state = PinGateState(
        exists ? PinGateStatus.locked : PinGateStatus.needsSetup,
      );
    } catch (_) {
      // Fail closed: never leave the router stuck in `checking` forever.
      if (ref.mounted) {
        state = const PinGateState(PinGateStatus.locked);
      }
    }
  }

  /// Called right after Firebase sign-in/register. Returns true when the UI
  /// must open PIN creation immediately (no code for this uid on device).
  Future<bool> prepareOnLogin(AuthUser? user) async {
    final fullUid = user != null && !user.isAnonymous ? user.uid : null;
    if (fullUid == null) return false;
    try {
      final verification = ref.read(verificationServiceProvider);
      final owner = await verification.accessCodeOwnerUid();
      if (shouldResetCodeForLogin(ownerUid: owner, fullUserUid: fullUid)) {
        await verification.resetCodeForUser(fullUid);
        if (!ref.mounted) return false;
        state = const PinGateState(PinGateStatus.needsSetup);
        return true;
      }
      final exists = await verification.accessCodeExists();
      if (!ref.mounted) return false;
      state = PinGateState(
        exists ? PinGateStatus.locked : PinGateStatus.needsSetup,
      );
      return !exists;
    } catch (_) {
      if (ref.mounted) {
        state = const PinGateState(PinGateStatus.locked);
      }
      return false;
    }
  }

  /// Called by CodeEnteringScreen after a valid PIN, successful creation or
  /// biometric authentication.
  void unlock() => state = const PinGateState(PinGateStatus.unlocked);

  /// Re-read secure storage and close the gate again (e.g. after a code reset).
  void relock() => _checkCode();
}
