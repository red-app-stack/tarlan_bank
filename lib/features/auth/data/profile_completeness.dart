import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';

/// Profile fields that must be present before a signed-in user can use the
/// app. Firebase Auth owns the password, so it is not part of the stored
/// profile and is never checked here.
enum ProfileField { fullName, phoneNumber, email }

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Fields missing or unusable in a `users/{uid}` document.
///
/// Legacy documents (old schema, Google's minimal first-sign-in profile or an
/// app update that added a field) are read as raw maps: `UserProfile.fromMap`
/// deliberately throws on incomplete data, so it cannot be used for this
/// check.
List<ProfileField> missingProfileFields(Map<String, dynamic> data) {
  final missing = <ProfileField>[];

  final name = data['fullName'];
  if (name is! String ||
      name
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .length <
          2) {
    missing.add(ProfileField.fullName);
  }

  final phone = data['phoneNumber'];
  if (phone is! String || !_validPhone(phone)) {
    missing.add(ProfileField.phoneNumber);
  }

  final email = data['email'];
  if (email is! String || !_emailPattern.hasMatch(email.trim())) {
    missing.add(ProfileField.email);
  }

  return missing;
}

bool _validPhone(String value) {
  try {
    normalizePhone(value);
    return true;
  } on ValidationFailure {
    return false;
  }
}

/// True when every required profile field is present and usable.
bool isProfileComplete(Map<String, dynamic> data) =>
    missingProfileFields(data).isEmpty;
