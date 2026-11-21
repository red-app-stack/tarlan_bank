import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarlan_bank/models/exchange_rate.dart';

import 'exchange_rates_snapshot.dart';

class ExchangeRateCache {
  ExchangeRateCache(this._prefs);

  static const _ratesKey = 'exchange_rates_cache';
  static const _checkedKey = 'exchange_rates_checked_at';
  static const _seenKey = 'exchange_rates_seen_updated_at';

  final SharedPreferences _prefs;

  ExchangeRatesSnapshot? read() {
    final raw = _prefs.getString(_ratesKey);
    final checked = _prefs.getInt(_checkedKey);
    final seen = _prefs.getInt(_seenKey);
    if (raw == null || checked == null || seen == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    final rates = <ExchangeRate>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final from = item['fromCurrency'];
      final to = item['toCurrency'];
      if (from is! String || to is! String) continue;
      rates.add(ExchangeRate.fromMap('${from}_$to', item));
    }
    if (rates.isEmpty) return null;
    return ExchangeRatesSnapshot(
      rates: rates,
      checkedAt: DateTime.fromMillisecondsSinceEpoch(checked, isUtc: true),
      latestUpdatedAt: DateTime.fromMillisecondsSinceEpoch(seen, isUtc: true),
    );
  }

  Future<void> write(ExchangeRatesSnapshot snapshot) async {
    if (snapshot.rates.isEmpty) return;
    final encoded = jsonEncode(
      snapshot.rates
          .map(
            (rate) => {
              'fromCurrency': rate.from,
              'toCurrency': rate.to,
              'rate': rate.rate,
              'updatedAt': rate.updatedAt.millisecondsSinceEpoch,
            },
          )
          .toList(),
    );
    await _prefs.setString(_ratesKey, encoded);
    await _prefs.setInt(_checkedKey, snapshot.checkedAt.millisecondsSinceEpoch);
    await _prefs.setInt(
      _seenKey,
      snapshot.latestUpdatedAt.millisecondsSinceEpoch,
    );
  }
}
