import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.photoUrl,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String photoUrl;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw NotFoundFailure('users/${doc.id} has no data');
    }
    return UserProfile.fromMap(doc.id, data);
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    final fullName = map['fullName'];
    final phone = map['phoneNumber'];
    if (fullName is! String || phone is! String) {
      throw ValidationFailure('Invalid user profile for $uid');
    }
    return UserProfile(
      uid: uid,
      email: _string(map['email']),
      fullName: fullName,
      phoneNumber: phone,
      photoUrl: _string(map['profilePictureUrl']),
      role: _string(map['role'], fallback: 'customer'),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'profilePictureUrl': photoUrl,
    'role': role,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}

String _string(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

DateTime? _date(Object? value) => switch (value) {
  Timestamp t => t.toDate(),
  DateTime d => d,
  _ => null,
};
