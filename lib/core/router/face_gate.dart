import 'package:tarlan_bank/core/router/access_policy.dart' show guestRoutes;
import 'package:tarlan_bank/core/router/routes.dart' show Routes;

/// Gate/auth screens must never be captured as a resume target: chaining them
/// produces `/faceVerify?target=/codeEntering?target=...` and a redirect loop.
const Set<String> faceGateScreens = {
  Routes.loading,
  Routes.login,
  Routes.codeEntering,
  Routes.faceVerify,
};

/// Where face verification sends the user once it is done (or cancelled).
String? resumableFaceTarget(String? uriString) {
  if (uriString == null || uriString.isEmpty) return null;
  final path = Uri.tryParse(uriString)?.path ?? uriString;
  if (faceGateScreens.contains(path)) return null;
  return uriString;
}

String faceRouteFor(String location) {
  final target = resumableFaceTarget(location);
  return Uri(
    path: Routes.faceVerify,
    queryParameters: {'target': ?target},
  ).toString();
}

/// The face gate never redirects away from another gate/auth screen — that is
/// what made PIN and face bounce off each other forever.
///
/// Guest routes stay reachable normally (feature gate, not an app lock). The
/// one exception is [scanAfterPin]: immediately after a PIN create/confirm on
/// a new device the scan must run, so even home is challenged once.
bool faceExempt(String location, {bool scanAfterPin = false}) {
  if (faceGateScreens.contains(location)) return true;
  if (scanAfterPin) return false;
  return guestRoutes.contains(location);
}
