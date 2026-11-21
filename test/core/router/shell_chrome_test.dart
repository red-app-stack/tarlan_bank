import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/router/routes.dart';

void main() {
  group('shell top-bar visibility', () {
    test('shown on branch roots', () {
      for (final route in branchRootLocations) {
        expect(showShellTopBarFor(route), isTrue, reason: route);
      }
    });

    test('hidden on every nested screen from all branches', () {
      const nested = [
        Routes.paymentsHistory,
        Routes.transfersPhone,
        Routes.transfersSelf,
        Routes.transfersCard,
        Routes.transfersConvert,
        Routes.transfersQr,
        Routes.transfersHistory,
        Routes.transfersDetails,
        Routes.accountsCreate,
        Routes.accountsDetails,
        Routes.menuSecurity,
        Routes.menuInvestments,
        Routes.menuChangePassword,
        Routes.menuLinkedAccounts,
      ];
      for (final route in nested) {
        expect(showShellTopBarFor(route), isFalse, reason: route);
      }
    });
  });
}
