import 'package:tarlan_bank/models/exchange_rate.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shimmer/shimmer.dart';

class CurrencyRate {
  final String code;
  final String symbol;
  final Color iconColor;
  final double sell;
  final double buy;

  CurrencyRate({
    required this.code,
    required this.symbol,
    required this.iconColor,
    required this.sell,
    required this.buy,
  });
}

class CurrencyRatesCard extends StatelessWidget {
  final Map<String, Map<String, ExchangeRate>> exchangeRates;
  final bool isLoading;

  const CurrencyRatesCard({
    super.key,
    required this.exchangeRates,
    this.isLoading = false,
  });

  List<CurrencyRate> _transformRates(
      Map<String, Map<String, ExchangeRate>> exchangeRates) {
    final colorMap = {
      'USD': const Color(0xFF4CAF50),
      'EUR': const Color(0xFF2196F3),
      'GBP': const Color(0xFF9C27B0),
      'RUB': const Color(0xFFFF9800),
    };

    final List<CurrencyRate> currencyRates = [];

    exchangeRates.forEach((fromCurrency, toCurrencies) {
      if (toCurrencies.containsKey('KZT')) {
        final rate = toCurrencies['KZT']!.rate;
        currencyRates.add(CurrencyRate(
          code: fromCurrency,
          symbol: getCurrencySymbol(fromCurrency),
          iconColor: colorMap[fromCurrency] ?? Colors.grey,
          sell: rate * 0.995,
          buy: rate * 1.005,
        ));
      }
    });

    currencyRates.sort((a, b) => a.buy.compareTo(b.buy));
    return currencyRates;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rates = _transformRates(exchangeRates);

    final Color baseColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final Color highlightColor = theme.brightness == Brightness.dark
        ? Colors.grey[600]!
        : Colors.grey[100]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _header('Валюта', theme),
              const Spacer(),
              _header('Продать', theme),
              const Spacer(),
              _header('Купить', theme),
            ],
          ),
        ),
        if (isLoading || rates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Shimmer.fromColors(
              // Use defined solid colors here
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                children: List.generate(
                  4, // number of placeholder rows
                  (_) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        _shimmerIcon(baseColor),
                        const SizedBox(width: 12),
                        SizedBox(
                            width: 50, child: _shimmerText(theme, baseColor)),
                        const Spacer(),
                        SizedBox(
                            width: 80, child: _shimmerText(theme, baseColor)),
                        const Spacer(),
                        SizedBox(
                            width: 80, child: _shimmerText(theme, baseColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!isLoading && rates.isNotEmpty)
          ...rates.map((rate) => _currencyRow(rate, theme)),
      ],
    );
  }

  Widget _header(String text, ThemeData theme) {
    return Text(text, style: theme.textTheme.bodySmall);
  }

  Widget _currencyRow(CurrencyRate rate, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _currencyIcon(rate.iconColor, rate.symbol, theme),
          const SizedBox(width: 12),
          SizedBox(
            child: Text(rate.code, style: theme.textTheme.titleLarge),
          ),
          const Spacer(),
          _priceColumn('${rate.sell.toStringAsFixed(2)} KZT', theme), // ₸
          const Spacer(),
          _priceColumn('${rate.buy.toStringAsFixed(2)} KZT', theme),
        ],
      ),
    );
  }

  Widget _priceColumn(String price, ThemeData theme) {
    return Text(
      price,
      style: theme.textTheme.titleLarge,
    );
  }

  Widget _currencyIcon(Color color, String symbol, ThemeData theme) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _shimmerIcon(Color color) {
    // The color passed here is replaced by the shimmer gradient
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _shimmerText(ThemeData theme, Color color) {
    // The color passed here is replaced by the shimmer gradient
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      height: 16,
    );
  }
}
