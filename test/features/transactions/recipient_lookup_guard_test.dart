import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/transactions/data/recipient_lookup_guard.dart';

void main() {
  test('blocks after repeated failures and clears on success', () {
    final guard = RecipientLookupGuard(
      maxFailures: 3,
      cooldown: const Duration(seconds: 30),
    );
    guard.registerFailure();
    guard.registerFailure();
    expect(guard.isBlocked, false);
    guard.registerFailure();
    expect(guard.isBlocked, true);
    guard.registerSuccess();
    expect(guard.isBlocked, false);
  });
}
