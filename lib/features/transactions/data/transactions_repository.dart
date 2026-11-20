import 'transaction_model.dart';

/// Transactions boundary — the money-moving seam.
///
/// IMPORTANT (see MIGRATION_PLAN.md §4): balance validation lives ONLY here
/// (pure core: `transfer_validation.dart`).
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
  ///
  /// Party shape follows [type]: `deposit` has no sender ([fromAccountId] null),
  /// `withdrawal` no recipient ([toAccountId] null); transfers require both.
  Future<BankTransaction> createTransaction({
    String? fromAccountId,
    String? toAccountId,
    required double amount,
    required String currency,
    required TransactionType type,
    String? message,
  });

  /// Newest-first history visible to the signed-in user (either party),
  /// optionally narrowed to one account and a date range (ISO-8601 strings).
  Future<List<BankTransaction>> fetchHistory({
    String? accountNumber,
    String? startDate,
    String? endDate,
  });

  /// Cancels/reverses a transaction through the validated path.
  /// The ledger is create-only (immutable) — a reversal is a compensating
  /// entry written by the TRUSTED validator. The demo impl has no trusted
  /// path and throws [ServerFailure] (501) instead of writing blind.
  Future<void> cancelTransaction(String transactionId);
}
