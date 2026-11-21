import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/exchange/data/exchange_rates_snapshot.dart';
import 'package:tarlan_bank/models/exchange_rate.dart';

ExchangeRate _rate(String to, {int daysOld = 0}) => ExchangeRate(
  from: 'USD',
  to: to,
  rate: 400 + daysOld.toDouble(),
  updatedAt: DateTime.now().toUtc().subtract(Duration(days: daysOld)),
);

void main() {
  test('parses document-shaped rates strictly', () {
    final rate = ExchangeRate.fromMap('USD_KZT', {
      'fromCurrency': 'USD',
      'toCurrency': 'KZT',
      'rate': 423.5,
      'updatedAt': DateTime.utc(2026, 11, 21).millisecondsSinceEpoch,
    });
    expect(rate.rate, 423.5);
    expect(rate.updatedAt, DateTime.utc(2026, 11, 21));
  });

  test('rejects bad rate documents', () {
    expect(
      () => ExchangeRate.fromMap('USD_KZT', {
        'fromCurrency': 'USD',
        'toCurrency': 'KZT',
        'rate': -1,
      }),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => ExchangeRate.fromMap('USD_EUR', {
        'fromCurrency': 'USD',
        'toCurrency': 'KZT',
        'rate': 1,
      }),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('nests rates and finds the newest update', () {
    final rates = [_rate('KZT', daysOld: 2), _rate('EUR', daysOld: 5)];
    expect(nestedRates(rates)['USD']?['KZT']?.rate, 402);
    expect(latestUpdate(rates), rates.first.updatedAt);
  });

  test('ttl helpers use a 24 hour window', () {
    final now = DateTime.utc(2026, 11, 21, 12);
    expect(
      isCacheExpired(now.subtract(const Duration(hours: 23)), now),
      isFalse,
    );
    expect(
      isCacheExpired(now.subtract(const Duration(hours: 25)), now),
      isTrue,
    );
    expect(isRateStale(now.subtract(const Duration(hours: 23)), now), isFalse);
    expect(isRateStale(now.subtract(const Duration(hours: 25)), now), isTrue);
  });
}
