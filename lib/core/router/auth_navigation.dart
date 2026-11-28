import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/auth/providers/pin_gate_provider.dart';

import 'pin_gate.dart' show pinRouteFor;

/// Final destination after email/Google sign-in or profile completion.
///
/// A full account without a device PIN must create one first; the original
/// target is preserved in the PIN route's `target` query parameter.
Future<String> destinationAfterAuth(
  WidgetRef ref, {
  required String target,
  bool anonymous = false,
}) async {
  if (anonymous) return target;
  final needsCreation = await ref
      .read(pinGateProvider.notifier)
      .prepareOnLogin(ref.read(authRepositoryProvider).currentUser);
  return needsCreation ? pinRouteFor(location: target, mode: 'create') : target;
}
