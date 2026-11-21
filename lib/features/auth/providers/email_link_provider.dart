import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

import 'auth_providers.dart';

/// Android App Link / iOS Universal Link stream. `uriLinkStream` also replays
/// the cold-start link, so subscribe early (MyApp.build) — no separate
/// getInitialLink() call needed.
final emailLinkUriProvider = StreamProvider<Uri>((ref) {
  return AppLinks().uriLinkStream;
});

/// Applies the Firebase `oobCode` from a verification link, refreshes the
/// auth state and returns the user to the app. Other link modes (password
/// reset, sign-in) are ignored here.
Future<void> handleEmailLink(WidgetRef ref, Uri uri) async {
  final code = verificationCodeFrom(uri);
  if (code == null) return;

  try {
    final repo = ref.read(authRepositoryProvider);
    await repo.applyEmailActionCode(code);
    final verified = await repo.refreshEmailVerification();
    ref.invalidate(authStateProvider);
    if (verified && ref.read(currentUserProvider) != null) {
      // Closes the verification dialog too (offAllNamed removes all routes).
      await navigateResetGlobal(Routes.main);
    }
  } on AppFailure {
    // Keep the current screen; the dialog's "Проверить" button is the fallback
    // if the deep link could not be applied.
  }
}

/// Pure extraction: only verifyEmail links (or links without an explicit mode)
/// may supply an oobCode to apply. Never applies password-reset / sign-in codes.
String? verificationCodeFrom(Uri uri, {int depth = 0}) {
  if (depth > 3) return null;
  final mode = uri.queryParameters['mode'];
  if (mode != null && mode != 'verifyEmail') return null;
  final code = uri.queryParameters['oobCode'];
  if (code != null && code.isNotEmpty) return code;

  // Firebase wraps the real auth action in a `link=` query parameter:
  // /__/auth/links?link=https://.../__/auth/action?...&oobCode=...
  final nested = uri.queryParameters['link'];
  if (nested == null || nested.isEmpty) return null;
  return verificationCodeFrom(
    Uri.parse(Uri.decodeComponent(nested)),
    depth: depth + 1,
  );
}
