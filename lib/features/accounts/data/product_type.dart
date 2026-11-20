import 'package:tarlan_bank/features/accounts/data/account_model.dart';

/// Maps the UI's legacy product names to the D8 account products.
/// 'card' is an instrument, so it opens the `current` account (the old REST
/// API used 'card' as an account type); 'transfer' = installment = credit.
AccountType accountTypeFromProduct(String product) {
  switch (product.toLowerCase()) {
    case 'deposit':
      return AccountType.deposit;
    case 'credit':
    case 'transfer':
      return AccountType.credit;
    default:
      return AccountType.current;
  }
}
