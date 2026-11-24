import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/router/access_policy.dart' show AccessLevel;
import 'package:tarlan_bank/core/router/face_gate.dart';
import 'package:tarlan_bank/core/router/pin_gate.dart'
    show PinGateStatus, pinRequired;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/auth/providers/face_gate_provider.dart'
    show FaceGateStatus, faceRequired;

void main() {
  group('face gate cannot loop with the PIN gate', () {
    test('gate screens are never captured as a face resume target', () {
      for (final route in [
        Routes.loading,
        Routes.login,
        Routes.codeEntering,
        Routes.faceVerify,
      ]) {
        expect(resumableFaceTarget(route), isNull, reason: route);
        expect(
          resumableFaceTarget('$route?target=%2Ftransfers'),
          isNull,
          reason: route,
        );
      }
    });

    test('real destinations survive, including their query string', () {
      expect(resumableFaceTarget('/transfers'), '/transfers');
      const target = '/accounts/create?type=card';
      expect(resumableFaceTarget(target), target);
      expect(Uri.parse(faceRouteFor(target)).queryParameters['target'], target);
    });

    test('a PIN screen target produces a clean face location', () {
      final uri = Uri.parse(faceRouteFor('/codeEntering?target=%2Ftransfers'));
      expect(uri.path, Routes.faceVerify);
      expect(uri.queryParameters['target'], isNull);
    });

    test('face is not challenged while the PIN gate is unsatisfied', () {
      for (final pin in [
        PinGateStatus.checking,
        PinGateStatus.locked,
        PinGateStatus.needsSetup,
      ]) {
        final pinChallenge = pinRequired(AccessLevel.full, pin);
        expect(pinChallenge, isTrue, reason: '$pin');
        expect(
          faceRequired(AccessLevel.full, FaceGateStatus.required) &&
              !pinChallenge,
          isFalse,
          reason: '$pin',
        );
      }
      expect(pinRequired(AccessLevel.full, PinGateStatus.unlocked), isFalse);
      expect(
        faceRequired(AccessLevel.full, FaceGateStatus.required) &&
            !pinRequired(AccessLevel.full, PinGateStatus.unlocked),
        isTrue,
      );
    });
  });

  group('faceExempt', () {
    test('gate/auth screens are always exempt', () {
      for (final route in [
        Routes.loading,
        Routes.login,
        Routes.reauth,
        Routes.codeEntering,
        Routes.faceVerify,
      ]) {
        expect(faceExempt(route), isTrue, reason: route);
        expect(faceExempt(route, scanAfterPin: true), isTrue, reason: route);
      }
    });

    test('guest routes are normally usable, but not right after PIN', () {
      expect(faceExempt(Routes.home), isTrue);
      expect(faceExempt(Routes.menu), isTrue);
      expect(faceExempt(Routes.home, scanAfterPin: true), isFalse);
      expect(faceExempt(Routes.menu, scanAfterPin: true), isFalse);
    });

    test('protected routes always challenge', () {
      expect(faceExempt(Routes.transfers), isFalse);
      expect(faceExempt(Routes.accounts), isFalse);
    });
  });
}
