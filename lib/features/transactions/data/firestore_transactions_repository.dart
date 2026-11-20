import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:uuid/uuid.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';

import 'transaction_model.dart';
import 'transactions_repository.dart';
import 'transfer_validation.dart';

/// Firestore implementation of [TransactionsRepository] (database `tarlan`).
/// DEMO GRADE — see MIGRATION_PLAN.md §4 and the `firestore.rules` header.
///
/// A transfer is ONE Firestore transaction: read sender + recipient →
/// [planTransfer] (the pure validation seam) → write both new balances and the
/// create-only ledger entry atomically. Firestore auto-retries the whole
/// read-validate-write on contention, so two concurrent transfers can never
/// both pass the sufficiency check against the same stale balance.
///
/// What rules add on top: balance >= 0, currency + ownership verified on BOTH
/// parties, immutable ledger. What rules CANNOT enforce (demo caveat):
/// cross-account atomicity/sufficiency — this client transaction does, and a
/// malicious client could bypass it. Production swaps this class for a trusted
/// callable behind the same interface; [planTransfer] lifts over unchanged.
///
/// Offline: `runTransaction` needs the server; when unreachable it fails with
/// [NetworkFailure] — never an unvalidated blind write (D3).
class FirestoreTransactionsRepository implements TransactionsRepository {
  FirestoreTransactionsRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
    Uuid? uuid,
  })  : _db = firestore ?? tarlanFirestore(),
        _auth = auth ?? fb.FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _db.collection('accounts');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthFailure();
    return uid;
  }

  @override
  Future<BankTransaction> createTransaction({
    String? fromAccountId,
    String? toAccountId,
    required double amount,
    required String currency,
    required TransactionType type,
    String? message,
  }) async {
    final uid = _uid;
    if (message != null && message.length > 280) {
      throw const ValidationFailure('Message is too long (max 280 characters)');
    }
    // Client UUID + create-only rules = idempotency key (D7).
    final txId = _uuid.v4();
    final txRef = _transactions.doc(txId);

    try {
      await _db.runTransaction((tx) async {
        // ALL reads first (Firestore transaction requirement).
        final fromDoc = fromAccountId == null
            ? null
            : await tx.get(_accounts.doc(fromAccountId));
        final toDoc = toAccountId == null
            ? null
            : await tx.get(_accounts.doc(toAccountId));
        if (fromDoc != null && !fromDoc.exists) {
          throw NotFoundFailure('Account $fromAccountId not found');
        }
        if (toDoc != null && !toDoc.exists) {
          throw NotFoundFailure('Account $toAccountId not found');
        }
        final from = fromDoc == null ? null : Account.fromFirestore(fromDoc);
        final to = toDoc == null ? null : Account.fromFirestore(toDoc);
        if (from != null && from.ownerId != uid) {
          throw const AuthFailure('You do not own the sender account');
        }

        final plan = planTransfer(
          type: type,
          amount: amount,
          currency: currency,
          from: from,
          to: to,
        );

        // Writes: both balances + the immutable ledger entry, atomically.
        if (from != null) {
          tx.update(_accounts.doc(from.number), {
            'balance': plan.fromBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (to != null) {
          tx.update(_accounts.doc(to.number), {
            'balance': plan.toBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        tx.set(txRef, {
          'amount': roundMoney(amount),
          'currency': currency,
          'type': type.wireName,
          'status': TransactionStatus.completed.name,
          if (from != null) 'fromAccountId': from.number,
          if (to != null) 'toAccountId': to.number,
          if (from != null) 'fromOwnerId': from.ownerId,
          if (to != null) 'toOwnerId': to.ownerId,
          'createdAt': FieldValue.serverTimestamp(),
          if (message != null && message.isNotEmpty) 'message': message,
        });
      });
      // Read back so createdAt carries the committed server timestamp.
      final snap = await txRef.get();
      return BankTransaction.fromFirestore(snap);
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<List<BankTransaction>> fetchHistory({
    String? accountNumber,
    String? startDate,
    String? endDate,
  }) async {
    final uid = _uid;
    final start = _parseDate(startDate, 'startDate');
    var end = _parseDate(endDate, 'endDate');
    // Date-only end bound is inclusive of the whole day.
    if (end != null && endDate!.trim().length == 10) {
      end = end.add(const Duration(days: 1));
    }
    try {
      // Either party. OR-query: rules evaluate each branch against the
      // owner-scoped read rule; both composite indexes exist
      // (firestore.indexes.json: fromOwnerId/toOwnerId + createdAt desc).
      final snap = await _transactions
          .where(Filter.or(
            Filter('fromOwnerId', isEqualTo: uid),
            Filter('toOwnerId', isEqualTo: uid),
          ))
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      final list = snap.docs.map(BankTransaction.fromFirestore).where((t) {
        if (accountNumber != null &&
            t.fromAccountId != accountNumber &&
            t.toAccountId != accountNumber) {
          return false;
        }
        final created = t.createdAt;
        if (created == null) return true; // pending local write
        if (start != null && created.isBefore(start)) return false;
        if (end != null && !created.isBefore(end)) return false;
        return true;
      }).toList();
      return list;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  DateTime? _parseDate(String? value, String name) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      throw ValidationFailure('Invalid $name (expected ISO-8601): $value');
    }
    return parsed;
  }

  @override
  Future<void> cancelTransaction(String transactionId) async {
    // The ledger is create-only; a reversal is a compensating entry that only
    // the TRUSTED validator may write (production callable). The demo has no
    // trusted path, so refuse loudly instead of writing blind (D3/§4).
    throw const ServerFailure(
        501, 'Cancellation requires the trusted validator (not wired yet)');
  }
}
