import 'package:tarlan_bank/core/router/routes.dart';

/// Keys the server puts in an FCM data payload to request an in-app route.
/// `route` is canonical; `target` is accepted for older payloads.
const String notificationRouteKey = 'route';
const String notificationTargetKey = 'target';

/// Only in-app destinations may be opened from a notification. A whitelist
/// keeps a malformed (or hostile) payload from opening arbitrary locations —
/// anything unknown falls back to the home tab.
const Set<String> _allowedRoutes = {
  // Shell tabs.
  Routes.home,
  Routes.payments,
  Routes.transfers,
  Routes.accounts,
  Routes.menu,
  Routes.main,
  // Nested destinations.
  Routes.paymentsHistory,
  Routes.transfersPhone,
  Routes.transfersSelf,
  Routes.transfersCard,
  Routes.transfersConvert,
  Routes.transfersQr,
  Routes.transfersHistory,
  Routes.transfersDetails,
  Routes.accountsCreate,
  Routes.accountsDetails,
  Routes.menuSecurity,
  Routes.menuInvestments,
  Routes.menuChangePassword,
  Routes.menuLinkedAccounts,
  // Overlays outside the shell.
  Routes.profile,
  Routes.chatbot,
  // Legacy aliases (navigateToGlobal maps these to current paths).
  Routes.cardDetails,
  Routes.paymentHistory,
  Routes.transferHistory,
  Routes.transferDetails,
  Routes.createAccount,
  Routes.investments,
  Routes.changePassword,
  Routes.linkedAccounts,
  Routes.phoneTransfer,
  Routes.selfTransfer,
  Routes.cardTransfer,
  Routes.convertation,
  Routes.qrTransfer,
  Routes.securitySettings,
};

/// Extracts a safe navigation location from an FCM data payload.
///
/// Returns the raw location (including any query string) when its path is a
/// known in-app destination, otherwise [Routes.home]. Values that are not
/// absolute in-app paths are rejected; auth/technical routes are never
/// reachable from a push payload.
String notificationRouteFrom(Map<String, dynamic> data) {
  final raw = data[notificationRouteKey] ?? data[notificationTargetKey];
  if (raw is! String) return Routes.home;
  final candidate = raw.trim();
  if (!candidate.startsWith('/') || candidate.startsWith('//')) {
    return Routes.home;
  }
  final path = candidate.split('?').first;
  if (!_allowedRoutes.contains(path)) return Routes.home;
  return candidate;
}
