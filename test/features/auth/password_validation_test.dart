import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/auth/data/password_validation.dart';

void main() {
  group('password policy', () {
    test('accepts Latin and Cyrillic passwords meeting all four rules', () {
      expect(isStrongPassword('Password1!'), true);
      expect(isStrongPassword('Пароль1!'), true);
      expect(validateNewPassword('Password1!'), isNull);
    });

    test('rejects short / no digit / no letter / no special', () {
      final cases = {
        'Ab1!': [PasswordRule.minLength],
        'Password!': [PasswordRule.digit],
        '12345678': [PasswordRule.letter, PasswordRule.special],
        'Password1': [PasswordRule.special],
      };
      cases.forEach((password, expected) {
        expect(passwordRuleFailures(password), expected, reason: password);
      });
    });

    test('empty and null fail with the length message', () {
      expect(validateNewPassword(null), PasswordRule.minLength);
      expect(validateNewPassword(''), PasswordRule.minLength);
    });

    test('reports every unmet rule at once', () {
      expect(passwordRuleFailures('abc'), [
        PasswordRule.minLength,
        PasswordRule.digit,
        PasswordRule.special,
      ]);
    });

    test('unicode letters and non-ASCII special characters count', () {
      expect(isStrongPassword('Қазақстан1№'), true);
      expect(isStrongPassword('Пароль1_'), true);
    });
  });
}
