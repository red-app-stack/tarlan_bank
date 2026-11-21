import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';
import 'package:tarlan_bank/models/exchange_rate.dart';

import 'exchange_repository.dart';

class FirestoreExchangeRepository implements ExchangeRepository {
  FirestoreExchangeRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? tarlanFirestore();

  final FirebaseFirestore _db;

  @override
  Future<List<ExchangeRate>> readRates() async {
    try {
      final snap = await _db.collection('exchange_rates').get();
      return _parse(snap);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Stream<List<ExchangeRate>> watchRates() {
    return _db.collection('exchange_rates').snapshots().map(_parse);
  }

  List<ExchangeRate> _parse(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(ExchangeRate.fromFirestore).toList();
}
