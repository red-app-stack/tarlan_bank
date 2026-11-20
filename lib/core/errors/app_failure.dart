/// Typed application failures.
///
/// Replaces the old `catch (e) { print(...); return null; }` pattern. Repositories
/// throw a sealed [AppFailure] so callers can handle each case exhaustively and
/// surface a meaningful message in the UI instead of swallowing errors.
library;

sealed class AppFailure implements Exception {
  const AppFailure(this.message, [this.cause]);

  /// Human-readable, UI-safe description.
  final String message;

  /// Original error, if any (kept for logging, never shown raw to the user).
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Connectivity / timeout / DNS — the request never reached the server.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network unavailable', super.cause]);
}

/// The server responded with a non-success status.
final class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode, [String? message, Object? cause])
      : super(message ?? 'Server error ($statusCode)', cause);

  final int statusCode;
}

/// Authentication / authorization problem (bad credentials, expired session).
final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Not authenticated', super.cause]);
}

/// Client-side validation failed (insufficient balance, bad input, etc.).
final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Invalid request', super.cause]);
}

/// A requested resource does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found', super.cause]);
}

/// Anything not yet classified.
final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unexpected error', super.cause]);
}