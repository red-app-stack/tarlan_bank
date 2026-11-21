/// A protected destination the user wanted before authentication, plus the
/// location to fall back to when anonymous sign-in is chosen (access denied).
class AuthIntent {
  const AuthIntent({required this.target, required this.origin});

  final String target;
  final String origin;
}
