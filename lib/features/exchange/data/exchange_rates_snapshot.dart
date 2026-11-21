import 'package:tarlan_bank/models/exchange_rate.dart';

const Duration ratesTtl = Duration(hours: 24);

class ExchangeRatesSnapshot {
  const ExchangeRatesSnapshot({
    required this.rates,
    required this.checkedAt,
    required this.latestUpdatedAt,
    this.isRefreshing = false,
  });

  final List<ExchangeRate> rates;
  final DateTime checkedAt;
  final DateTime latestUpdatedAt;
  final bool isRefreshing;

  Map<String, Map<String, ExchangeRate>> get nested => nestedRates(rates);

  ExchangeRatesSnapshot copyWith({bool? isRefreshing}) => ExchangeRatesSnapshot(
    rates: rates,
    checkedAt: checkedAt,
    latestUpdatedAt: latestUpdatedAt,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );
}

bool isCacheExpired(DateTime checkedAt, [DateTime? now]) =>
    (now ?? DateTime.now()).difference(checkedAt) >= ratesTtl;

bool isRateStale(DateTime updatedAt, [DateTime? now]) =>
    (now ?? DateTime.now()).difference(updatedAt) >= ratesTtl;

DateTime latestUpdate(List<ExchangeRate> rates) => rates.fold<DateTime>(
  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  (latest, rate) => rate.updatedAt.isAfter(latest) ? rate.updatedAt : latest,
);

Map<String, Map<String, ExchangeRate>> nestedRates(List<ExchangeRate> rates) {
  final result = <String, Map<String, ExchangeRate>>{};
  for (final rate in rates) {
    result.putIfAbsent(rate.from, () => {})[rate.to] = rate;
  }
  return result;
}
