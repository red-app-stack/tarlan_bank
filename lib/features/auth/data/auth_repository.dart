import 'auth_user.dart';
import 'reauth_method.dart';

/// Auth boundary. Implementations: a temporary stub (scaffolding), then
/// `FirebaseAuthRepository` (demo), swappable to a custom-JWT impl later.
///
/// All methods throw a sealed [AppFailure] on error; they never return null to
/// signal failure. OTP / verification specifics are intentionally left to the
/// implementation so the interface survives the Firebase migration.
abstract interface class AuthRepository {
  /// Emits the current user (null when signed out). Drives the router redirect.
  Stream<AuthUser?> authStateChanges();

  /// Currently signed-in user, or null.
  AuthUser? get currentUser;

  Future<AuthUser> login({required String email, required String password});

  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  });

  /// Google sign-in (registered Google accounts only). Creates the profile
  /// doc on first sign-in; no phone number is available from Google.
  Future<AuthUser> signInWithGoogle();

  /// Firebase anonymous session for guests: main/menu + exchange rates +
  /// notifications only. No Firestore private data (rules deny it).
  Future<AuthUser> signInAnonymously();

  /// Sends Firebase's verification email to the current user. Firebase
  /// enforces its own server-side rate limit; the UI additionally throttles
  /// resends to one per 60 seconds (EmailVerificationCooldownStore).
  Future<void> sendEmailVerification();

  /// Calls `reload()` and returns the refreshed `emailVerified` flag.
  Future<bool> refreshEmailVerification();

  /// Applies an `oobCode` from a Firebase verification App Link, then reloads
  /// the session so `emailVerified` is fresh.
  Future<void> applyEmailActionCode(String code);

  Future<void> logout();

  Future<void> deleteAccount();

  /// Providers linked to the current user, used by the reauth screen.
  Future<Set<ReauthMethod>> availableReauthMethods();

  /// Confirm the current session with an email/password credential.
  Future<void> reauthenticateWithPassword({
    required String email,
    required String password,
  });

  /// Same, using an interactive Google sign-in.
  Future<void> reauthenticateWithGoogle();
}
