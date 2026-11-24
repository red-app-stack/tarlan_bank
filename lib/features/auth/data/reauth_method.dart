/// Which Firebase providers can re-confirm the current session.
///
/// Kept as a pure enum + mapping so the UI can decide which controls to show
/// without importing Firebase, and so the mapping is unit-testable.
enum ReauthMethod { password, google }

/// `User.providerData[].providerId` → controls we know how to reauthenticate.
///
/// Unknown providers are ignored: showing a button that cannot complete the
/// reauth would be worse than asking the user to sign in from scratch.
Set<ReauthMethod> reauthMethodsFromProviderIds(Iterable<String> providerIds) {
  final methods = <ReauthMethod>{};
  for (final id in providerIds) {
    switch (id) {
      case 'password':
        methods.add(ReauthMethod.password);
      case 'google.com':
        methods.add(ReauthMethod.google);
    }
  }
  return methods;
}
