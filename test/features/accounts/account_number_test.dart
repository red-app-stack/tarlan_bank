import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/accounts/data/firestore_accounts_repository.dart';

void main() {
  test('generated numbers are 16 digits, first non-zero', () {
    final random = Random(42);
    for (var i = 0; i < 500; i++) {
      final number = generateAccountNumber(random);
      expect(number.length, 16);
      expect(
        RegExp(r'^[1-9][0-9]{15}$').hasMatch(number),
        true,
        reason: 'bad number: $number',
      );
    }
  });

  test('deterministic given a seeded Random (testability contract)', () {
    expect(generateAccountNumber(Random(7)), generateAccountNumber(Random(7)));
  });

  test('different seeds give different numbers', () {
    expect(
      generateAccountNumber(Random(1)),
      isNot(generateAccountNumber(Random(2))),
    );
  });
}
