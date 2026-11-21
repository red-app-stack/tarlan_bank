import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/data/account_model.dart';
import '../data/transaction_model.dart';

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
