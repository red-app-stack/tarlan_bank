import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/firestore_accounts_repository.dart';
import 'account_deletion_repository.dart';
import 'profile_completeness.dart' as completeness;
import 'reauth_method.dart';

import 'auth_repository.dart';
import 'auth_user.dart';

/// Firebase Auth repository. Firebase Auth owns identity; `users/{uid}`
/// owns the profile. Errors map to sealed [AppFailure].
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _firestore = firestore ?? tarlanFirestore(),
       _google = googleSignIn ?? GoogleSignIn.instance,
       _accounts = FirestoreAccountsRepository(
         firestore: firestore ?? tarlanFirestore(),
       );

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _google;
  final AccountsRepository _accounts;
  late final AccountDeletionRepository _deletion = AccountDeletionRepository(
    _firestore,
  );

  /// 7.x requires exactly one initialize() call whose future completes before
  /// any other method. Reset on failure so a retry can initialize again.
  Future<void>? _googleInit;

  Future<void> _ensureGoogleInit() async {
    final pending = _googleInit;
    if (pending != null) {
      await pending;
      return;
    }
    final future = _google.initialize();
    _googleInit = future;
    try {
      await future;
    } catch (_) {
      _googleInit = null;
      rethrow;
    }
  }

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
        'profilePictureUrl': created.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Phone-transfer lookup index (E.164 doc ID). accountNumber is linked
      // later, when the first debit account is opened.
      await _firestore
          .collection('phone_index')
          .doc(normalizePhone(phoneNumber))
          .set({'uid': created.uid});
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
    // Seeding happens AFTER the rollback boundary: a failed seed must not
    // delete a live Auth account.
    final user = created;
    await _ensureStarter(user.uid);
    return AuthUser(uid: user.uid, email: user.email);
  }

  /// Best-effort new-user seed. Auth/profile writes must never be blocked by
  /// a transient ledger failure; the seeded account/card can be retried on a
  /// later sign-in.
  Future<void> _ensureStarter(String uid) async {
    try {
      await _accounts.ensureStarterDebitAccount(ownerId: uid);
    } catch (_) {}
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      // 7.x: initialize once, then authenticate() (throws on cancellation).
      await _ensureGoogleInit();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google sign-in did not return an ID token');
      }
      // 7.x exposes only an ID token; Firebase accepts credential(idToken:).
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) {
        throw const AuthFailure('Google sign-in returned no user');
      }
      // Rules require a profile string for phoneNumber; Google never shares
      // one. Empty string satisfies the invariant and disables phone lookup.
      await _ensureProfile(user, photoUrl: account.photoUrl);
      return _mapUser(user)!;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  /// First Google sign-in creates the minimal profile. Never overwrites an
  /// existing one (e.g. an email/password account linked to the same UID).
  Future<void> _ensureProfile(fb.User user, {String? photoUrl}) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    final url = photoUrl?.trim().isNotEmpty == true
        ? photoUrl!.trim()
        : user.photoURL;
    if (!snap.exists || url == null || url.isEmpty) {
      if (!snap.exists) {
        // Google's photo URL is the avatar source for provider sign-ins.
        // An empty string keeps the field present for email accounts that
        // later link Google, without fabricating an image.
        await ref.set({
          'email': user.email ?? '',
          'fullName': user.displayName ?? user.email ?? 'User',
          'phoneNumber': '',
          'role': 'customer',
          'profilePictureUrl': url ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _ensureStarter(user.uid);
      }
      return;
    }
    final existing = snap.data()?['profilePictureUrl'] as String?;
    if (existing != url) {
      await ref.update({
        'profilePictureUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<bool> isProfileComplete(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      if (!snap.exists) return false;
      return completeness.isProfileComplete(snap.data() ?? const {});
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<void> completeProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    String? password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const AuthFailure('Sign in before completing your profile');
    }
    final phone = normalizePhone(phoneNumber);
    final name = fullName.trim();
    final mail = email.trim();
    try {
      final profile = _firestore.collection('users').doc(user.uid);
      final snap = await profile.get();
      final oldPhone = snap.data()?['phoneNumber'];
      final creatingProfile = !snap.exists;

      final batch = _firestore.batch();
      if (snap.exists) {
        // Firestore rules allow only these keys on an update. Email comes
        // from Firebase Auth and cannot be changed here.
        batch.set(profile, {
          'fullName': name,
          'phoneNumber': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.set(profile, {
          'email': mail,
          'fullName': name,
          'phoneNumber': phone,
          'role': 'customer',
          'profilePictureUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (oldPhone is String &&
          oldPhone.trim().isNotEmpty &&
          oldPhone != phone) {
        final previous = _tryNormalize(oldPhone);
        if (previous != null && previous != phone) {
          batch.delete(_firestore.collection('phone_index').doc(previous));
        }
      }
      batch.set(_firestore.collection('phone_index').doc(phone), {
        'uid': user.uid,
      });
      await batch.commit();
      if (creatingProfile) await _ensureStarter(user.uid);
      // Cosmetic mirror of the name; a stale email session may require a
      // recent login for Auth profile edits, which must not block the save.
      try {
        await user.updateDisplayName(name);
      } catch (_) {}

      // Password is optional: Google users can leave it blank, or set one to
      // sign in with the same email later. An existing email account with
      // this address already has a password, so linking is not needed.
      if (password != null && password.isNotEmpty) {
        try {
          await user.linkWithCredential(
            fb.EmailAuthProvider.credential(email: mail, password: password),
          );
        } on fb.FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
        }
      }
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  /// Legacy phone values may be unusable; never block profile completion.
  String? _tryNormalize(String value) {
    try {
      return normalizePhone(value);
    } on ValidationFailure {
      return null;
    }
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user == null) {
        throw const AuthFailure('Anonymous sign-in returned no user');
      }
      // No users/{uid} doc and no phone_index for guests: rules deny writes
      // to private collections for anonymous sessions.
      return _mapUser(user)!;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.email == null) {
      throw const AuthFailure('Sign in with an email account to verify it');
    }
    if (user.emailVerified) return;
    try {
      // Default Firebase-hosted handler on tarlan-bank.firebaseapp.com.
      // No custom domain / ActionCodeSettings needed; Console template owns
      // the continue URL. Firebase rate-limits repeat sends server-side.
      await user.sendEmailVerification(
        fb.ActionCodeSettings(
          // Default Firebase Hosting domain is already authorized; NEVER set
          // linkDomain to firebaseapp.com (Firebase rejects that).
          url: 'https://tarlan-bank.firebaseapp.com/',
          androidPackageName: 'com.tarlan.bank',
          handleCodeInApp: true,
        ),
      );
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
    } catch (e) {
      throw mapFirebaseError(e);
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> applyEmailActionCode(String code) async {
    try {
      await _auth.applyActionCode(code);
      await _auth.currentUser?.reload();
    } catch (e) {
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
    final uid = user.uid;
    try {
      final profile = await _firestore.collection('users').doc(uid).get();
      final phone = profile.data()?['phoneNumber'] as String?;
      // Firestore first: once Auth is deleted the token is gone and rules
      // would deny every cleanup write. A requires-recent-login failure
      // leaves an Auth account with no profile — the user can retry after
      // signing in again.
      await _deletion.deleteAllFor(uid, phone: phone);
      await user.delete();
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<Set<ReauthMethod>> availableReauthMethods() async {
    final user = _auth.currentUser;
    if (user == null) return const {};
    return reauthMethodsFromProviderIds(
      user.providerData.map((info) => info.providerId),
    );
  }

  @override
  Future<void> reauthenticateWithPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const AuthFailure();
    try {
      await user.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(
          email: user.email!.trim(),
          password: password,
        ),
      );
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure();
    try {
      await _ensureGoogleInit();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google sign-in did not return an ID token');
      }
      await user.reauthenticateWithCredential(
        fb.GoogleAuthProvider.credential(idToken: idToken),
      );
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
      isAnonymous: user.isAnonymous,
      emailVerified: user.emailVerified,
    );
  }
}
