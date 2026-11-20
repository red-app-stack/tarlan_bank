import 'package:tarlan_bank/core/errors/app_failure.dart';

/// Normalizes a phone number to E.164 (`+770****4567`).
///
/// Fixes the old schema's varchar(10) free-for-all. KZ convention in this
/// app: 10 digits starting with 7 (as stored historically, e.g. 7701234567)
/// or 11 digits with country code 7 / legacy 8 prefix. A bare 10-digit
/// subscriber number WITHOUT the country code is indistinguishable from the
/// stored 10-digit format, so it is not guessed — callers pass the full
/// number. Used as the `phone_index/{phone}` document ID for recipient lookup.
String normalizePhone(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  // KZ legacy 8-prefix: 8 + 10-digit national (11 total) or 8 + the app's
  // historical 9-digit local part (10 total, mirrors stored 7XXXXXXXXX).
  if (digits.startsWith('8') && (digits.length == 10 || digits.length == 11)) {
    digits = '7${digits.substring(1)}';
  }
  if (digits.length < 10 || digits.length > 15) {
    throw ValidationFailure('Invalid phone number: $input');
  }
  return '+$digits';
}
