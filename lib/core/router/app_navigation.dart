import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import 'package:tarlan_bank/routes/app_routes.dart' show Routes;

/// TRANSITIONAL navigation seam. Every migrated screen calls these three
/// functions instead of `Get.toNamed/offNamed/offAllNamed`; the final
/// go_router cutover changes only this file (to `context.go/push/replace`).
Future<void> navigateTo(
  BuildContext context,
  String route, {
  Object? arguments,
}) async => await Get.toNamed(route, arguments: arguments);

Future<void> navigateReplace(
  BuildContext context,
  String route, {
  Object? arguments,
}) async => await Get.offNamed(route, arguments: arguments);

Future<void> navigateReset(BuildContext context, String route) async {
  if (!context.mounted) return;
  await Get.offAllNamed(route);
}

/// Main shell with a target tab, used after create-account / auth flows.
Future<void> navigateToMainTab(BuildContext context, String tab) =>
    navigateReplace(context, Routes.main, arguments: {'targetRoute': tab});
