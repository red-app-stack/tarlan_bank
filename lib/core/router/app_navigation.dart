import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/core/router/shell_index_provider.dart';

/// Root navigator shared with GoRouter. All navigation goes through go_router;
/// this key is exposed for dialogs/snackbars that need a BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const _aliases = {
  Routes.main: Routes.home,
  Routes.paymentHistory: Routes.paymentsHistory,
  Routes.phoneTransfer: Routes.transfersPhone,
  Routes.selfTransfer: Routes.transfersSelf,
  Routes.cardTransfer: Routes.transfersCard,
  Routes.convertation: Routes.transfersConvert,
  Routes.qrTransfer: Routes.transfersQr,
  Routes.transferHistory: Routes.transfersHistory,
  Routes.transferDetails: Routes.transfersDetails,
  Routes.createAccount: Routes.accountsCreate,
  Routes.cardDetails: Routes.accountsDetails,
  Routes.securitySettings: Routes.menuSecurity,
  Routes.investments: Routes.menuInvestments,
};

String _location(String route, Object? arguments) {
  final mapped = _aliases[route] ?? route;
  if (mapped == Routes.accountsCreate &&
      arguments is Map &&
      arguments['extra'] != null) {
    return '$mapped?type=${Uri.encodeComponent(arguments['extra'].toString())}';
  }
  return mapped;
}

BuildContext? get _context => rootNavigatorKey.currentContext;

GoRouter? get _router {
  final context = _context;
  return context == null ? null : GoRouter.maybeOf(context);
}

/// Navigate from anywhere (screens and controllers) without depending on GetX.
/// `arguments` is mirrored into the legacy bridge until each screen is migrated.
Future<void> navigateToGlobal(String route, {Object? arguments}) async {
  final router = _router;
  if (router == null) return;
  final location = _location(route, arguments);
  // Profile/chatbot are overlay routes outside the shell: push so the branch
  // index and shell state underneath stay intact.
  if (location == Routes.profile || location == Routes.chatbot) {
    router.push(location);
    return;
  }
  router.go(location, extra: arguments);
}

Future<void> navigateReplaceGlobal(String route, {Object? arguments}) async {
  final router = _router;
  if (router == null) return;
  // Top-level go_router routes reset the stack, matching old offNamed.
  router.go(_location(route, arguments), extra: arguments);
}

Future<void> navigateResetGlobal(String route) async {
  final router = _router;
  if (router == null) return;
  router.go(route);
}

void navigateBack({Object? result}) {
  final router = _router;
  if (result == null && router != null && router.canPop()) {
    router.pop();
    return;
  }
  rootNavigatorKey.currentState?.pop(result);
}

// Context-taking wrappers kept so already-migrated screens compile unchanged.
Future<void> navigateTo(
  BuildContext context,
  String route, {
  Object? arguments,
}) => navigateToGlobal(route, arguments: arguments);

Future<void> navigateReplace(
  BuildContext context,
  String route, {
  Object? arguments,
}) => navigateReplaceGlobal(route, arguments: arguments);

Future<void> navigateReset(BuildContext context, String route) =>
    navigateResetGlobal(route);

/// Main shell with a target tab, used after create-account / auth flows.
Future<void> navigateToMainTab(BuildContext context, String tab) async {
  if (!context.mounted) return;
  ProviderScope.containerOf(context)
      .read(pendingShellTabProvider.notifier)
      .request(tab);
  final router = _router;
  if (router != null) router.go(Routes.home);
}
