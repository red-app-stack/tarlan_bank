import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/exchange/data/rate_display.dart';
import 'package:tarlan_bank/features/exchange/data/exchange_rates_snapshot.dart';
import 'package:tarlan_bank/models/exchange_rate.dart';

void main() {
  ExchangeRate rate(String from, String to, double value) => ExchangeRate(
    from: from,
    to: to,
    rate: value,
    updatedAt: DateTime.utc(2026, 11, 20),
  );

  test('reads KZT-based documents by inverting them', () {
    final nested = nestedRates([
      rate('KZT', 'USD', 0.002223),
      rate('KZT', 'EUR', 0.0021),
      rate('KZT', 'GBP', 0.0018),
      rate('KZT', 'RUB', 0.011),
    ]);

    final rates = displayRates(nested);
    expect(rates.map((r) => r.code), containsAll(['USD', 'EUR', 'GBP', 'RUB']));
    final usd = rates.firstWhere((r) => r.code == 'USD');
    expect(usd.rateToKzt, closeTo(1 / 0.002223, 0.0001));
  });

  test('prefers direct X_KZT rates when present', () {
    final nested = nestedRates([
      rate('USD', 'KZT', 450),
      rate('KZT', 'USD', 0.002),
    ]);
    final usd = displayRates(nested).firstWhere((r) => r.code == 'USD');
    expect(usd.rateToKzt, 450);
  });

  test('ignores unsupported currencies', () {
    final nested = nestedRates([rate('KZT', 'JPY', 0.1)]);
    expect(displayRates(nested), isEmpty);
  });
}
