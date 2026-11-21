import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarlan_bank/features/exchange/data/exchange_rate_cache.dart';
import 'package:tarlan_bank/features/exchange/data/exchange_rates_snapshot.dart';
import 'package:tarlan_bank/models/exchange_rate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cache round-trips rates and timestamps', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = ExchangeRateCache(prefs);
    final updated = DateTime.utc(2026, 11, 21, 10);
    final snapshot = ExchangeRatesSnapshot(
      rates: [
        ExchangeRate(from: 'USD', to: 'KZT', rate: 423.5, updatedAt: updated),
      ],
      checkedAt: DateTime.utc(2026, 11, 21, 11),
      latestUpdatedAt: updated,
    );

    await cache.write(snapshot);
    final restored = cache.read();

    expect(restored, isNotNull);
    expect(restored!.rates.single.rate, 423.5);
    expect(restored.latestUpdatedAt, updated);
    expect(restored.checkedAt, DateTime.utc(2026, 11, 21, 11));
  });

  test('cache is null before first write', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(ExchangeRateCache(prefs).read(), isNull);
  });
}
