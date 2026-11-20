import 'package:tarlan_bank/models/transaction_model.dart';

/// Transactions boundary — the money-moving seam.
///
/// IMPORTANT (see MIGRATION_PLAN.md §4): balance validation lives ONLY here.
/// - Demo impl: client-side Firestore transaction + security rules (demo-grade).
/// - Production impl: trusted callable (Cloud Function / Node-on-Firestore).
/// Swapping the implementation must not change this interface or any consumer.
///
/// Offline rule: never perform unvalidated writes. When the trusted validator is
/// unreachable, transfers are disabled or queued as pending — not written blind.
///
/// Methods throw a sealed [AppFailure] on error (e.g. [ValidationFailure] for
/// insufficient balance).
abstract interface class TransactionsRepository {
  /// Validates balance atomically, then moves money and records the transaction.
  Future<Transaction> createTransaction({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String currency,
    required String type,
    String? message,
  });

  Future<List<Transaction>> fetchHistory({
    String? accountNumber,
    String? startDate,
    String? endDate,
  });

  /// Cancels/reverses a transaction through the validated path.
  Future<void> cancelTransaction(String transactionId);
}
