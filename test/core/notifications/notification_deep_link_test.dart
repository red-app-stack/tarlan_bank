import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/notifications/notification_deep_link.dart';
import 'package:tarlan_bank/core/router/routes.dart';

void main() {
  group('notificationRouteFrom', () {
    test('prefers route over target', () {
      expect(
        notificationRouteFrom({
          'route': Routes.transfersHistory,
          'target': Routes.home,
        }),
        Routes.transfersHistory,
      );
    });

    test('accepts target key and preserves query parameters', () {
      expect(
        notificationRouteFrom({'target': '${Routes.accountsCreate}?type=card'}),
        '${Routes.accountsCreate}?type=card',
      );
    });

    test('falls back home for unknown, external or malformed values', () {
      for (final value in [
        '/unknown',
        'https://example.com',
        '//example.com',
        'home',
        '',
        Routes.login,
        '/loading',
      ]) {
        expect(
          notificationRouteFrom({'route': value}),
          Routes.home,
          reason: value,
        );
      }
    });

    test('falls back home when no key or a non-string value is present', () {
      expect(notificationRouteFrom(const {}), Routes.home);
      expect(notificationRouteFrom({'route': 42}), Routes.home);
    });

    test('maps legacy alias targets through to the router', () {
      expect(
        notificationRouteFrom({'route': Routes.cardDetails}),
        Routes.cardDetails,
      );
    });
  });
}
