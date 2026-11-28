import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/auth/data/profile_completeness.dart';

void main() {
  Map<String, dynamic> doc({
    Object? name = 'Tarlan User',
    Object? phone = '+77012345678',
    Object? email = 'user@example.com',
  }) => {'fullName': name, 'phoneNumber': phone, 'email': email};

  test('complete profile passes', () {
    expect(isProfileComplete(doc()), isTrue);
    expect(missingProfileFields(doc()), isEmpty);
  });

  test('Google minimal profile asks for name and phone only', () {
    final missing = missingProfileFields(
      doc(name: 'user@example.com', phone: ''),
    );
    expect(missing, [ProfileField.fullName, ProfileField.phoneNumber]);
  });

  test('legacy document without email asks for email', () {
    final missing = missingProfileFields(doc()..remove('email'));
    expect(missing, [ProfileField.email]);
  });

  test('invalid phone is treated as missing', () {
    expect(missingProfileFields(doc(phone: 'abc')), [ProfileField.phoneNumber]);
  });

  test('legacy 10-digit and 8-prefix phones remain valid', () {
    expect(isProfileComplete(doc(phone: '7012345678')), isTrue);
    expect(isProfileComplete(doc(phone: '87012345678')), isTrue);
  });
}
