import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/features/auth/data/reauth_method.dart';

void main() {
  group('reauthMethodsFromProviderIds', () {
    test('uses only the providers the account actually has', () {
      expect(reauthMethodsFromProviderIds(['password']), {
        ReauthMethod.password,
      });
      expect(reauthMethodsFromProviderIds(['google.com']), {
        ReauthMethod.google,
      });
      expect(reauthMethodsFromProviderIds(['password', 'google.com']), {
        ReauthMethod.password,
        ReauthMethod.google,
      });
    });

    test('unknown or empty provider lists offer no reauth control', () {
      expect(reauthMethodsFromProviderIds(const []), isEmpty);
      expect(reauthMethodsFromProviderIds(['phone', 'apple.com']), isEmpty);
    });
  });
}
