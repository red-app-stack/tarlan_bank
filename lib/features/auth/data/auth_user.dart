/// Backend-agnostic authenticated user.
///
/// Deliberately minimal and independent of the REST/Firebase wire shape so the
/// auth repository can be swapped (custom JWT -> Firebase Auth) without touching
/// consumers. Mapping from a backend payload lives in the repository impl.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.isAnonymous = false,
    this.emailVerified = false,
  });

  final String uid;
  final String? email;
  final String? fullName;
  final String? phoneNumber;

  /// Firebase anonymous session: guest access only (main/menu, exchange
  /// rates, notifications). Never treated as a full user by guards or rules.
  final bool isAnonymous;

  /// Firebase's `emailVerified` flag. Google sessions are already verified;
  /// anonymous guests have no email. UX only — enforce in Firestore rules if
  /// private data must require verification.
  final bool emailVerified;
}
