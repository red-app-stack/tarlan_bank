import 'package:tarlan_bank/generated/app_localizations.dart';

import 'password_validation.dart';

/// The ONLY place where a password rule becomes human-readable. New locales
/// are added in lib/l10n/*.arb, never as literals in domain code or screens.
extension PasswordRuleLabel on PasswordRule {
  String label(AppLocalizations l) => switch (this) {
    PasswordRule.minLength => l.passwordMinLength,
    PasswordRule.digit => l.passwordDigit,
    PasswordRule.letter => l.passwordLetter,
    PasswordRule.special => l.passwordSpecial,
  };
}
