import 'package:tarlan_bank/core/errors/app_failure.dart';

/// Normalizes a phone to E.164 for `phone_index/{phone}` lookups.
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

/// Formats legacy 10-digit, E.164 and `8...` values for display only.
String formatDisplayPhone(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return trimmed;
  if (digits.startsWith('8') && digits.length == 11) {
    digits = '7${digits.substring(1)}';
  }
  // KZ: country code 7 + 9 national digits (10 digits total stored legacy,
  // or 11 with the leading 7). Render as +7 (XXX) XXX-XX-XX.
  // Stored 10-digit legacy values are the national part as-is; 11-digit
  // values begin with the country code 7. Both render as +7 (XXX) XXX-XX-XX.
  String? national;
  if (digits.length == 10) {
    national = digits;
  } else if (digits.length == 11 && digits.startsWith('7')) {
    national = digits.substring(1);
  }
  if (national != null && national.length == 10) {
    return '+7 (${national.substring(0, 3)}) '
        '${national.substring(3, 6)}-${national.substring(6, 8)}-'
        '${national.substring(8, 10)}';
  }
  return '+$digits';
}
