import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/transactions/widgets/lookup_identity_row.dart';

void main() {
  test('lookup dots cycle one to three dots', () {
    expect(lookupDots(0), '.');
    expect(lookupDots(1), '..');
    expect(lookupDots(2), '...');
    expect(lookupDots(3), '.');
  });
}
