import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';

import 'auth_repository.dart';
import 'auth_user.dart';

/// Firebase Auth implementation of [AuthRepository] (Week 1 cutover).
///
/// Identity lives in Firebase Auth; the `users/{uid}` Firestore doc holds the
/// profile (fullName, phoneNumber, role) that Auth itself does not store for
/// email/password accounts. Registration writes both, with best-effort
/// rollback of the Auth account if the profile write fails.
///
/// Errors are mapped to sealed [AppFailure] via [mapFirebaseError];
/// nothing raw escapes to consumers.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? tarlanFirestore();

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthUser?> authStateChanges() {
    // Firebase's stream replays the current state to each new subscriber
    // (unlike a raw broadcast controller), so no manual replay is needed.
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthFailure('Sign-in returned no user');
      }
      return _mapUser(user)!;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    fb.User? created;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      created = cred.user;
      if (created == null) {
        throw const AuthFailure('Registration returned no user');
      }
      await created.updateDisplayName(fullName.trim());
      // Profile doc — mirrors the remodeled `users` table (no password /
      // security-question columns; Firebase Auth owns credentials).
      await _firestore.collection('users').doc(created.uid).set({
        'email': email.trim(),
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Phone-transfer lookup index (E.164 doc ID). accountNumber is linked
      // later, when the first current account is opened.
      await _firestore
          .collection('phone_index')
          .doc(normalizePhone(phoneNumber))
          .set({'uid': created.uid});
      return AuthUser(
        uid: created.uid,
        email: created.email,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
      );
    } catch (e) {
      // Best-effort rollback: never leave an Auth account without its profile.
      if (created != null) {
        try {
          await created.delete();
        } catch (_) {
          // Rollback failed (e.g. offline); the profile write can be retried
          // on next sign-in. Logged by the caller's failure handler.
        }
      }
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure();
    try {
      // Clean the phone index first (best-effort: a malformed stored phone
      // must not block account deletion; a stale index entry resolves to a
      // missing account and reads as "no recipient").
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final phone = profile.data()?['phoneNumber'] as String?;
      if (phone != null && phone.isNotEmpty) {
        try {
          await _firestore
              .collection('phone_index')
              .doc(normalizePhone(phone))
              .delete();
        } on AppFailure {
          // skip index cleanup; see above
        }
      }
      // Profile next: if the Auth delete then fails (requires-recent-login),
      // the user can retry; rules allow owner delete of users/{uid}.
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  /// Plugin singletons own their streams; nothing to close here.
  void dispose() {}

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      fullName: user.displayName,
      // phoneNumber is null for email/password accounts; the registered
      // number lives in users/{uid}. Consumers needing it read the profile.
      phoneNumber: user.phoneNumber,
    );
  }
}
