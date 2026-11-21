/// Firebase Auth session identity. Profile data lives in `UserProfile`.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.isAnonymous = false,
    this.emailVerified = false,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
  final bool emailVerified;
}
