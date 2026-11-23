import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/router/access_policy.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

void main() {
  group('first login on device', () {
    test('resets a code owned by nobody or another uid', () {
      expect(
        shouldResetCodeForLogin(ownerUid: null, fullUserUid: 'uid-1'),
        isTrue,
      );
      expect(
        shouldResetCodeForLogin(ownerUid: 'uid-2', fullUserUid: 'uid-1'),
        isTrue,
      );
    });

    test('keeps a code created by the same uid', () {
      expect(
        shouldResetCodeForLogin(ownerUid: 'uid-1', fullUserUid: 'uid-1'),
        isFalse,
      );
    });

    test('guests do not own or reset codes', () {
      expect(
        shouldResetCodeForLogin(ownerUid: 'uid-1', fullUserUid: null),
        isFalse,
      );
    });
  });

  group('pinRequired', () {
    test('only a signed-in user who has not entered the PIN is challenged', () {
      for (final gate in [
        PinGateStatus.checking,
        PinGateStatus.locked,
        PinGateStatus.needsSetup,
      ]) {
        expect(pinRequired(AccessLevel.full, gate), isTrue, reason: '$gate');
      }
      expect(pinRequired(AccessLevel.full, PinGateStatus.unlocked), isFalse);
      expect(pinRequired(AccessLevel.guest, PinGateStatus.locked), isFalse);
      expect(pinRequired(AccessLevel.signedOut, PinGateStatus.locked), isFalse);
    });
  });

  group('pinChallengeFor', () {
    const target = '/transfers/phone';

    test('checking routes through internal loading and keeps the target', () {
      final uri = Uri.parse(
        pinChallengeFor(gate: PinGateStatus.checking, location: target),
      );
      expect(uri.path, Routes.loading);
      expect(uri.queryParameters['target'], target);
    });

    test('saved PIN opens the entry flow, missing PIN opens creation', () {
      final locked = Uri.parse(
        pinChallengeFor(gate: PinGateStatus.locked, location: target),
      );
      expect(locked.path, Routes.codeEntering);
      expect(locked.queryParameters['target'], target);
      expect(locked.queryParameters['mode'], isNull);

      final setup = Uri.parse(
        pinChallengeFor(gate: PinGateStatus.needsSetup, location: target),
      );
      expect(setup.path, Routes.codeEntering);
      expect(setup.queryParameters['target'], target);
      expect(setup.queryParameters['mode'], 'create');
    });

    test('unlocked user proceeds normally', () {
      expect(
        pinChallengeFor(gate: PinGateStatus.unlocked, location: target),
        target,
      );
    });
  });

  group('resumablePinTarget', () {
    test('never resumes on the transient loading route or code screen', () {
      expect(resumablePinTarget(Routes.loading), isNull);
      expect(resumablePinTarget('/loading?target=x'), isNull);
      expect(resumablePinTarget(Routes.codeEntering), isNull);
      expect(resumablePinTarget('/codeEntering?mode=create'), isNull);
      expect(resumablePinTarget(''), isNull);
    });

    test('keeps a real destination, including its query string', () {
      const target = '/accounts/create?type=card';
      expect(resumablePinTarget(target), target);
      expect(
        Uri.parse(pinRouteFor(location: target)).queryParameters['target'],
        target,
      );
    });
  });

  group('loadingExitFor', () {
    test('stays on the spinner while storage or auth is unresolved', () {
      expect(
        loadingExitFor(
          authLevel: AccessLevel.full,
          gate: PinGateStatus.checking,
          target: Routes.accounts,
        ),
        isNull,
      );
      expect(
        loadingExitFor(
          authLevel: AccessLevel.loading,
          gate: PinGateStatus.locked,
          target: Routes.accounts,
        ),
        isNull,
      );
    });

    test('signed-out user goes to login', () {
      expect(
        loadingExitFor(
          authLevel: AccessLevel.signedOut,
          gate: PinGateStatus.needsSetup,
        ),
        Routes.login,
      );
    });

    test('guest or unlocked user resumes where they intended', () {
      expect(
        loadingExitFor(
          authLevel: AccessLevel.guest,
          gate: PinGateStatus.locked,
          target: Routes.home,
        ),
        Routes.home,
      );
      expect(
        loadingExitFor(
          authLevel: AccessLevel.full,
          gate: PinGateStatus.unlocked,
          target: Routes.home,
        ),
        Routes.home,
      );
    });

    test('locked user resumes into PIN entry, no-PIN into creation', () {
      final locked = Uri.parse(
        loadingExitFor(
          authLevel: AccessLevel.full,
          gate: PinGateStatus.locked,
          target: Routes.accounts,
        )!,
      );
      expect(locked.path, Routes.codeEntering);
      expect(locked.queryParameters['target'], Routes.accounts);

      final setup = Uri.parse(
        loadingExitFor(
          authLevel: AccessLevel.full,
          gate: PinGateStatus.needsSetup,
          target: Routes.accounts,
        )!,
      );
      expect(setup.queryParameters['mode'], 'create');
    });
  });
}
