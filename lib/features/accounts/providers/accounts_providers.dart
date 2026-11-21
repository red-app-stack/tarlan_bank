import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/account_model.dart';
import '../data/accounts_repository.dart';
import '../data/card_model.dart';
import '../data/firestore_accounts_repository.dart';

/// Single swap point for the accounts backend (Firestore now).
final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return FirestoreAccountsRepository();
});

/// Realtime accounts of the signed-in user; empty when signed out.
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final repo = ref.watch(accountsRepositoryProvider);
  final backfilled = <String>{};
  return repo.watchAccounts(user.uid).map((accounts) {
    if (!backfilled.contains(user.uid)) {
      backfilled.add(user.uid);
      unawaited(repo.ensureRecipientIndexes(user.uid).catchError((_) {}));
    }
    return accounts;
  });
});

/// Realtime cards of the signed-in user; empty when signed out.
final cardsProvider = StreamProvider<List<BankCard>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(accountsRepositoryProvider).watchCards(user.uid);
});
