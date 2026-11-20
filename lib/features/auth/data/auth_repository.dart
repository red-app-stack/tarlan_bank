import 'auth_user.dart';

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

  Future<void> logout();

  Future<void> deleteAccount();
}