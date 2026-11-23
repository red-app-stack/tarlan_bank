import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/data/account_model.dart';
import '../../../core/providers/service_providers.dart';
import '../../accounts/providers/accounts_providers.dart';
import '../data/transaction_model.dart';
import '../data/recipient_lookup.dart';
import '../data/recipient_lookup_guard.dart';
import '../data/server_recipient_repository.dart';

/// The transaction opened on the details screen.
///
/// go_router builds every transfer screen with no constructor arguments, so
/// screens publish the transaction here immediately before navigating. The
/// details screen reads it and falls back to an empty state when it is null —
/// no global argument bridge involved.
class SelectedTransactionNotifier extends Notifier<BankTransaction?> {
  @override
  BankTransaction? build() => null;

  void select(BankTransaction? transaction) => state = transaction;
  void clear() => state = null;
}

final selectedTransactionProvider =
    NotifierProvider<SelectedTransactionNotifier, BankTransaction?>(
      SelectedTransactionNotifier.new,
    );

/// Last recipient resolved by a phone / account-number lookup on a transfer
/// screen. Kept in Riverpod state so the reactive UI rebuilds via `ref.watch`.
class TransferRecipientNotifier extends Notifier<Account?> {
  @override
  Account? build() => null;

  void set(Account? account) => state = account;
  void clear() => state = null;
}

final transferRecipientProvider =
    NotifierProvider<TransferRecipientNotifier, Account?>(
      TransferRecipientNotifier.new,
    );

class TransferLookupState {
  const TransferLookupState({
    this.recipient,
    this.account,
    this.pending = false,
    this.blocked = false,
  });

  final TransferRecipient? recipient;
  final Account? account;
  final bool pending;
  final bool blocked;
}

class TransferLookupNotifier extends Notifier<TransferLookupState> {
  final _guard = RecipientLookupGuard(
    maxFailures: 5,
    cooldown: const Duration(minutes: 2),
  );

  static const minVisibleLoading = Duration(milliseconds: 250);
  DateTime? _pendingSince;

  @override
  TransferLookupState build() => const TransferLookupState();

  void begin() {
    if (_guard.isBlocked) {
      state = TransferLookupState(blocked: true);
      return;
    }
    _pendingSince ??= DateTime.now();
    state = const TransferLookupState(pending: true);
  }

  Future<void> lookup({
    String? phoneNumber,
    String? accountNumber,
    bool scheduled = false,
  }) async {
    if (_guard.isBlocked) {
      state = TransferLookupState(blocked: true);
      return;
    }
    if (!scheduled && state.pending) return;
    _pendingSince ??= DateTime.now();
    state = const TransferLookupState(pending: true);
    try {
      TransferRecipient? recipient;
      try {
        recipient = await ref
            .read(recipientRepositoryProvider)
            .lookupRecipient(
              phoneNumber: phoneNumber,
              accountNumber: accountNumber,
            );
      } on Object {
        recipient = await ref
            .read(accountsRepositoryProvider)
            .lookupRecipient(
              phoneNumber: phoneNumber,
              accountNumber: accountNumber,
            );
      }
      if (recipient == null) {
        _guard.registerFailure();
        await _settle(TransferLookupState(blocked: _guard.isBlocked));
        return;
      }
      final account = await ref
          .read(accountsRepositoryProvider)
          .getAccount(recipient.accountNumber);
      _guard.registerSuccess();
      await _settle(
        TransferLookupState(recipient: recipient, account: account),
      );
    } on Object {
      _guard.registerFailure();
      await _settle(TransferLookupState(blocked: _guard.isBlocked));
    }
  }

  Future<void> _settle(TransferLookupState next) async {
    final since = _pendingSince;
    _pendingSince = null;
    if (since != null) {
      final remaining = minVisibleLoading - DateTime.now().difference(since);
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
    if (ref.mounted) state = next;
  }

  void clear() {
    _pendingSince = null;
    state = const TransferLookupState();
  }
}

final transferLookupProvider =
    NotifierProvider<TransferLookupNotifier, TransferLookupState>(
      TransferLookupNotifier.new,
    );

final recipientRepositoryProvider = Provider<ServerRecipientRepository>((ref) {
  return ServerRecipientRepository(dioManager: ref.watch(dioManagerProvider));
});
