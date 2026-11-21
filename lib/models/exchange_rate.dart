import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';

class ExchangeRate {
  const ExchangeRate({
    required this.from,
    required this.to,
    required this.rate,
    required this.updatedAt,
  });

  final String from;
  final String to;
  final double rate;
  final DateTime updatedAt;

  factory ExchangeRate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) throw NotFoundFailure('Exchange rate ${doc.id} missing');
    return ExchangeRate.fromMap(doc.id, data);
  }

  factory ExchangeRate.fromMap(String id, Map<String, dynamic> map) {
    final from = map['fromCurrency'];
    final to = map['toCurrency'];
    final value = map['rate'];
    final updated = map['updatedAt'];
    if (from is! String || to is! String || value is! num || value <= 0) {
      throw ValidationFailure('Invalid exchange rate $id');
    }
    if (id != '${from}_$to') {
      throw ValidationFailure('Exchange rate $id does not match its pair');
    }
    return ExchangeRate(
      from: from,
      to: to,
      rate: value.toDouble(),
      updatedAt: _parseUpdatedAt(updated),
    );
  }

  Map<String, dynamic> toMap() => {
    'fromCurrency': from,
    'toCurrency': to,
    'rate': rate,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

DateTime _parseUpdatedAt(Object? value) => switch (value) {
  Timestamp t => t.toDate().toUtc(),
  DateTime d => d.toUtc(),
  int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
};
