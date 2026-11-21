import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/transactions/data/recipient_lookup.dart';

void main() {
  test('initials use first and last name', () {
    expect(recipientInitials('Айбеков Азамат'), 'АА');
    expect(recipientInitials('Азамат'), 'А');
  });

  test('phone lookup tries E.164 and national KZ forms', () {
    final candidates = phoneIndexCandidates('701 234 56 78');
    expect(candidates.first, '+77012345678');
    expect(candidates, contains('+7012345678'));
  });

  test('legacy 8-prefix becomes 7', () {
    expect(phoneIndexCandidates('87012345678').first, '+77012345678');
    expect(phoneIndexCandidates('8888888888').first, '+78888888888');
  });
}
