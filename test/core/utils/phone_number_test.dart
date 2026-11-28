import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';

void main() {
  group('normalizePhone — KZ formats', () {
    test('all local variants normalize to the same E.164', () {
      const expected = '+7701234567';
      expect(normalizePhone('7701234567'), expected);
      expect(normalizePhone('8701234567'), expected);
      expect(normalizePhone('+7 (701) 234-567'), expected);
      expect(normalizePhone('+7701234567'), expected);
    });

    test('other international numbers pass through normalized', () {
      expect(normalizePhone('+1 (555) 123-4567'), '+15551234567');
      expect(
        normalizePhone('00441234567890'.replaceFirst('00', '')),
        '+441234567890',
      );
    });
  });

  group('normalizePhone — rejects garbage', () {
    test('too short / too long / empty throw ValidationFailure', () {
      expect(() => normalizePhone('12345'), throwsA(isA<ValidationFailure>()));
      expect(() => normalizePhone(''), throwsA(isA<ValidationFailure>()));
      expect(
        () => normalizePhone('1234567890123456'),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => normalizePhone('abcdefghij'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
