import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/utils/verification_dialog.dart' as verification;

/// Backwards-compatible entry point kept for callers that used to import this
/// file. The implementation is now a Riverpod-backed, go_router-safe dialog in
/// [verification] with no service-locator dependency.
Future<bool> showEmailConfirmationDialog({
  required String email,
  required BuildContext context,
}) => verification.showEmailConfirmationDialog(email: email, context: context);
