import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';

import 'exchange_repository.dart';

/// Free public rates API → Firestore `exchange_rates/{FROM_TO}` cache.
/// Guests may READ the cache (rules allow it) but never write; writes are only
/// attempted for registered users. Node is no longer involved in rates.
class FirestoreExchangeRepository implements ExchangeRepository {
  FirestoreExchangeRepository({
    Dio? dio,
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
  }) : _dio = dio ?? Dio(),
       _db = firestore ?? tarlanFirestore(),
       _auth = auth ?? fb.FirebaseAuth.instance;

  final Dio _dio;
  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  /// Must stay in sync with `rateCurrencies()` in firestore.rules.
  static const allowedCurrencies = ['USD', 'EUR', 'KZT', 'RUB', 'GBP'];

  @override
  Future<Map<String, double>> fetchRates({String base = 'KZT'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://open.er-api.com/v6/latest/$base',
      );
      final body = response.data;
      if (body == null || body['result'] != 'success') {
        throw ServerFailure(502, 'Exchange rate service returned no data');
      }
      final raw = body['rates'];
      if (raw is! Map) {
        throw ServerFailure(502, 'Exchange rate service returned no rates');
      }
      final rates = <String, double>{};
      final user = _auth.currentUser;
      final canWrite = user != null && !user.isAnonymous;
      final batch = _db.batch();
      for (final currency in allowedCurrencies) {
        if (currency == base) continue;
        final value = raw[currency];
        if (value is! num || value <= 0) continue;
        final rate = value.toDouble();
        rates[currency] = rate;
        if (canWrite) {
          batch.set(_db.collection('exchange_rates').doc('${base}_$currency'), {
            'fromCurrency': base,
            'toCurrency': currency,
            'rate': rate,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (rates.isEmpty) {
        throw ServerFailure(502, 'No supported rates returned');
      }
      if (canWrite) await batch.commit();
      return rates;
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }
}
