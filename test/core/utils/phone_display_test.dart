import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';

void main() {
  group('formatDisplayPhone', () {
    test('handles stored legacy, E.164 and 8-prefix values', () {
      expect(formatDisplayPhone('7701234567'), '+7 (770) 123-45-67');
      expect(formatDisplayPhone('+77012345678'), '+7 (701) 234-56-78');
      expect(formatDisplayPhone('8 (701) 234-56-78'), '+7 (701) 234-56-78');
    });

    test('empty input has no display value', () {
      expect(formatDisplayPhone(''), isEmpty);
      expect(formatDisplayPhone('   '), isEmpty);
    });

    test('falls back to E.164 for non-KZ numbers', () {
      expect(formatDisplayPhone('+44123456789'), '+44123456789');
    });
  });
}
