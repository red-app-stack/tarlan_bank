import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/server_transactions_repository.dart';
import '../data/transaction_model.dart';
import '../data/transactions_repository.dart';

/// Single swap point for the money-moving backend (MIGRATION_PLAN.md §4):
/// demo = client Firestore transactions; production = trusted callable.
/// No consumer changes when the implementation swaps.
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return ServerTransactionsRepository(
    dioManager: ref.watch(dioManagerProvider),
  );
});

/// Newest-first ledger history of the signed-in user, optionally narrowed to
/// one account (family argument = account number, null = all accounts).
/// Empty when signed out. Re-fetch after a transfer with
/// `ref.invalidate(transactionsHistoryProvider)`.
final transactionsHistoryProvider = FutureProvider.autoDispose
    .family<List<BankTransaction>, String?>((ref, accountNumber) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return const [];
      return ref
          .watch(transactionsRepositoryProvider)
          .fetchHistory(accountNumber: accountNumber);
    });
