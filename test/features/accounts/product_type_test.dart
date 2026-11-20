import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/data/product_type.dart';

void main() {
  test('legacy tile names map to D8 account products', () {
    expect(accountTypeFromProduct('card'), AccountType.current);
    expect(accountTypeFromProduct('deposit'), AccountType.deposit);
    expect(accountTypeFromProduct('credit'), AccountType.credit);
    expect(accountTypeFromProduct('transfer'), AccountType.credit);
    expect(accountTypeFromProduct('CARD'), AccountType.current);
    expect(accountTypeFromProduct('unknown'), AccountType.current);
  });
}
