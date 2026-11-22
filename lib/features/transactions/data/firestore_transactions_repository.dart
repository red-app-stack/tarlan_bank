import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';

import 'transaction_model.dart';
import 'transactions_repository.dart';

/// Read-only Firestore history source (database `tarlan`).
///
/// Money movement lives in the trusted Node service. Client code may read the
/// ledger but must never create entries or change balances; Firestore rules
/// deny those writes.
class FirestoreTransactionsRepository implements TransactionsRepository {
  FirestoreTransactionsRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
  }) : _db = firestore ?? tarlanFirestore(),
       _auth = auth ?? fb.FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

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
    throw const ServerFailure(
      501,
      'Money movement must go through the trusted Node server',
    );
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
          .where(
            Filter.or(
              Filter('fromOwnerId', isEqualTo: uid),
              Filter('toOwnerId', isEqualTo: uid),
            ),
          )
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
      501,
      'Cancellation requires the trusted validator (not wired yet)',
    );
  }
}
