import 'package:tarlan_bank/models/exchange_rate.dart';

class DisplayRate {
  const DisplayRate({required this.code, required this.rateToKzt});

  final String code;
  final double rateToKzt;
}

const displayCurrencies = ['USD', 'EUR', 'GBP', 'RUB'];

List<DisplayRate> displayRates(Map<String, Map<String, ExchangeRate>> nested) {
  final result = <DisplayRate>[];
  for (final code in displayCurrencies) {
    final direct = nested[code]?['KZT']?.rate;
    final inverse = nested['KZT']?[code]?.rate;
    final rate = (direct != null && direct > 0)
        ? direct
        : (inverse != null && inverse > 0)
        ? 1 / inverse
        : null;
    if (rate == null) continue;
    result.add(DisplayRate(code: code, rateToKzt: rate));
  }
  return result..sort((a, b) => a.rateToKzt.compareTo(b.rateToKzt));
}
