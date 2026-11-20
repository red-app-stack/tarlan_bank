import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/firebase/firestore_db.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/models/exchange_rate.dart';

import '../data/exchange_repository.dart';
import '../data/firestore_exchange_repository.dart';

/// Single swap point for the rates source (free API + Firestore cache).
final exchangeRepositoryProvider = Provider<ExchangeRepository>((ref) {
  return FirestoreExchangeRepository();
});

/// Realtime rates from the shared cache: `FROM` → {`TO`: ExchangeRate}.
/// Guests can read this collection (firestore.rules); empty while signed out.
final exchangeRatesProvider =
    StreamProvider<Map<String, Map<String, ExchangeRate>>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value(const {});
      return tarlanFirestore()
          .collection('exchange_rates')
          .snapshots()
          .map(_toNested);
    });

Map<String, Map<String, ExchangeRate>> _toNested(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  final result = <String, Map<String, ExchangeRate>>{};
  for (final doc in snap.docs) {
    final data = doc.data();
    final from = data['fromCurrency'] as String?;
    final to = data['toCurrency'] as String?;
    final rate = data['rate'];
    if (from == null || to == null || rate is! num) continue;
    final updated = data['updatedAt'];
    result.putIfAbsent(from, () => {})[to] = ExchangeRate(
      rate: rate.toDouble(),
      lastUpdated: updated is Timestamp
          ? updated.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
  return result;
}
