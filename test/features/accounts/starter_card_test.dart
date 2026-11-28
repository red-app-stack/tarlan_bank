import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/accounts/data/firestore_accounts_repository.dart';

void main() {
  test('new users start with 50,000 KZT', () {
    expect(FirestoreAccountsRepository.starterBalance, 50000);
  });

  test('starter card expires five years out in the same month', () {
    final expiry = FirestoreAccountsRepository.starterCardExpiry(
      DateTime(2026, 11, 28),
    );
    expect(expiry.month, 11);
    expect(expiry.year, 2031);
  });
}
