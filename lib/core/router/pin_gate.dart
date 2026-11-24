import 'package:tarlan_bank/core/router/access_policy.dart' show AccessLevel;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

/// Device PIN gate, deliberately separate from Firebase auth state.
///
/// Not entering the PIN does NOT block the app: the user keeps guest-level
/// access (home, menu, exchange rates). Only protected money features —
/// viewing accounts, transfers, history and settings — require the PIN.
enum PinGateStatus {
  /// Access-code existence is still being read from secure storage.
  checking,

  /// Full Firebase user, but no access code saved yet — creation flow.
  needsSetup,

  /// Access code exists, but this session has not unlocked it.
  locked,

  /// PIN or biometrics accepted for this process.
  unlocked,
}

class PinGateState {
  const PinGateState(this.status);

  final PinGateStatus status;
}

/// A signed-in user who has not entered the PIN this process is treated as a
/// guest for routing. Protected features then challenge for PIN/setup.
bool pinRequired(AccessLevel authLevel, PinGateStatus gate) =>
    authLevel == AccessLevel.full && gate != PinGateStatus.unlocked;

/// Never treat the transient loading route (or the PIN screen itself) as a
/// destination to resume after unlocking.
String? resumablePinTarget(String uriString) {
  final path = Uri.tryParse(uriString)?.path ?? uriString;
  if (path.isEmpty ||
      path == Routes.loading ||
      path == Routes.reauth ||
      path == Routes.codeEntering) {
    return null;
  }
  return uriString;
}

/// Builds the code-screen location, optionally forcing the creation flow and
/// preserving the protected location the user originally wanted.
String pinRouteFor({required String location, String? mode}) {
  final query = <String, String>{};
  if (mode != null) query['mode'] = mode;
  final target = resumablePinTarget(location);
  if (target != null) query['target'] = target;
  return Uri(path: Routes.codeEntering, queryParameters: query).toString();
}

/// Where to send a protected-feature request before the PIN is entered.
String pinChallengeFor({
  required PinGateStatus gate,
  required String location,
}) {
  switch (gate) {
    case PinGateStatus.checking:
      return Uri(
        path: Routes.loading,
        queryParameters: {'target': location},
      ).toString();
    case PinGateStatus.needsSetup:
      return pinRouteFor(location: location, mode: 'create');
    case PinGateStatus.locked:
      return pinRouteFor(location: location);
    case PinGateStatus.unlocked:
      return location;
  }
}

/// The loading route is internal: hand off once the storage check resolves,
/// preserving the original protected target from its query parameter.
String? loadingExitFor({
  required AccessLevel authLevel,
  required PinGateStatus gate,
  String? target,
}) {
  if (gate == PinGateStatus.checking || authLevel == AccessLevel.loading) {
    return null;
  }
  if (authLevel == AccessLevel.signedOut) return Routes.login;
  final destination = resumablePinTarget(target ?? '') ?? Routes.home;
  if (!pinRequired(authLevel, gate)) return destination;
  return gate == PinGateStatus.needsSetup
      ? pinRouteFor(location: destination, mode: 'create')
      : pinRouteFor(location: destination);
}

/// A full account that has not created its code on this device must never
/// inherit a previous account's PIN. Guests (null uid) are unaffected.
bool shouldResetCodeForLogin({
  required String? ownerUid,
  required String? fullUserUid,
}) {
  if (fullUserUid == null) return false;
  return ownerUid != fullUserUid;
}
