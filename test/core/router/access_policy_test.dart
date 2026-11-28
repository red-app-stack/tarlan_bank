import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/router/access_policy.dart';
import 'package:tarlan_bank/features/auth/data/auth_user.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

void main() {
  test('signed out: only public routes, everything else → login', () {
    for (final route in publicRoutes) {
      expect(
        redirectFor(level: AccessLevel.signedOut, location: route),
        isNull,
      );
    }
    for (final route in [Routes.home, Routes.convertation, Routes.profile]) {
      expect(
        redirectFor(level: AccessLevel.signedOut, location: route),
        Routes.login,
      );
    }
  });

  test('guest: main/menu + exchange + auth routes only', () {
    for (final route in [Routes.home, Routes.convertation, Routes.login]) {
      expect(
        redirectFor(level: AccessLevel.guest, location: route),
        isNull,
        reason: route,
      );
    }
    for (final route in [
      Routes.profile,
      Routes.phoneTransfer,
      Routes.cardTransfer,
      Routes.transferHistory,
      Routes.securitySettings,
      Routes.createAccount,
    ]) {
      expect(
        redirectFor(level: AccessLevel.guest, location: route),
        Routes.login,
        reason: route,
      );
    }
  });

  test('full user: login → main, other routes unchanged', () {
    expect(
      redirectFor(level: AccessLevel.full, location: Routes.login),
      Routes.home,
    );
    expect(
      redirectFor(level: AccessLevel.full, location: Routes.profile),
      isNull,
    );
  });

  test('stream still loading: no redirect', () {
    expect(
      redirectFor(level: AccessLevel.loading, location: Routes.profile),
      isNull,
    );
  });

  test('accessLevel reads the anonymous flag from AuthUser', () {
    expect(accessLevel(const AsyncLoading()), AccessLevel.loading);
    expect(accessLevel(const AsyncData(null)), AccessLevel.signedOut);
    expect(
      accessLevel(AsyncData(AuthUser(uid: 'anon', isAnonymous: true))),
      AccessLevel.guest,
    );
    expect(
      accessLevel(const AsyncData(AuthUser(uid: 'real'))),
      AccessLevel.full,
    );
  });

  group('auth intent', () {
    test('remembered for protected targets when signed out or guest', () {
      expect(
        shouldRememberAuthIntent(AccessLevel.signedOut, Routes.accounts),
        isTrue,
      );
      expect(
        shouldRememberAuthIntent(AccessLevel.guest, Routes.paymentsHistory),
        isTrue,
      );
    });

    test('never remembered for public/guest routes or full users', () {
      expect(
        shouldRememberAuthIntent(AccessLevel.signedOut, Routes.login),
        isFalse,
      );
      expect(shouldRememberAuthIntent(AccessLevel.guest, Routes.home), isFalse);
      expect(
        shouldRememberAuthIntent(AccessLevel.full, Routes.accounts),
        isFalse,
      );
      expect(
        shouldRememberAuthIntent(AccessLevel.loading, Routes.accounts),
        isFalse,
      );
    });
  });

  group('post-auth completion', () {
    test('recognised with a target query and distinct from gate screens', () {
      expect(isPostAuthStep(Routes.completeProfile), isTrue);
      expect(
        isPostAuthStep(
          Uri(
            path: Routes.completeProfile,
            queryParameters: {'target': Routes.home},
          ).toString(),
        ),
        isTrue,
      );
      for (final route in [
        Routes.codeEntering,
        Routes.faceVerify,
        Routes.home,
        Routes.login,
      ]) {
        expect(isPostAuthStep(route), isFalse, reason: route);
      }
    });
  });
}
