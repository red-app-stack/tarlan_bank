import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/auth/data/user_profile.dart';

void main() {
  const uid = 'u1';

  test('parses a complete profile with typed fields', () {
    final created = DateTime.utc(2026, 1, 2);
    final profile = UserProfile.fromMap(uid, {
      'email': 'a@b.c',
      'fullName': 'A B',
      'phoneNumber': '7701234567',
      'role': 'customer',
      'profilePictureUrl': 'https://example.com/a.png',
      'createdAt': Timestamp.fromDate(created),
    });

    expect(profile.uid, uid);
    expect(profile.fullName, 'A B');
    expect(profile.phoneNumber, '7701234567');
    expect(profile.photoUrl, 'https://example.com/a.png');
    expect(profile.createdAt!.toUtc().isAtSameMomentAs(created), isTrue);
    expect(profile.updatedAt, isNull);
  });

  test('rejects a malformed profile instead of leaking dynamic values', () {
    expect(
      () => UserProfile.fromMap(uid, {'fullName': 1, 'phoneNumber': '770'}),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('toMap round-trips scalar fields', () {
    final original = UserProfile.fromMap(uid, {
      'email': 'a@b.c',
      'fullName': 'A B',
      'phoneNumber': '7701234567',
      'role': 'customer',
    });
    final parsed = UserProfile.fromMap(uid, original.toMap());
    expect(parsed.fullName, original.fullName);
    expect(parsed.phoneNumber, original.phoneNumber);
    expect(parsed.photoUrl, original.photoUrl);
  });
}
