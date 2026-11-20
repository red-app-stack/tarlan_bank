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
  });

  final String uid;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
}