/// Registration password policy: minimum 8 characters, at least one digit,
/// one letter, one special character. Pure (no Flutter / no locale strings) so
/// UI, tests and a future trusted backend share exactly one rule set.
library;

const int passwordMinLength = 8;

/// Rules are returned as enum values; localization lives in the UI
/// (`password_rule_labels.dart`) so the domain never hardcodes Russian.
enum PasswordRule { minLength, digit, letter, special }

/// All unmet rules, in display order. Empty list == acceptable password.
List<PasswordRule> passwordRuleFailures(String password) {
  final failures = <PasswordRule>[];
  if (password.length < passwordMinLength) {
    failures.add(PasswordRule.minLength);
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    failures.add(PasswordRule.digit);
  }
  if (!password.contains(RegExp(r'\p{L}', unicode: true))) {
    failures.add(PasswordRule.letter);
  }
  if (!password.contains(RegExp(r'[^\p{L}\p{N}]', unicode: true))) {
    failures.add(PasswordRule.special);
  }
  return failures;
}

bool isStrongPassword(String password) =>
    passwordRuleFailures(password).isEmpty;

/// Form validator: null when valid, otherwise the first unmet rule.
PasswordRule? validateNewPassword(String? password) {
  if (password == null || password.isEmpty) return PasswordRule.minLength;
  final failures = passwordRuleFailures(password);
  return failures.isEmpty ? null : failures.first;
}
