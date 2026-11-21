import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/models/exchange_rate.dart';

import '../data/exchange_rate_cache.dart';
import '../data/exchange_rates_snapshot.dart';
import '../data/exchange_repository.dart';
import '../data/firestore_exchange_repository.dart';

final exchangeRepositoryProvider = Provider<ExchangeRepository>(
  (ref) => FirestoreExchangeRepository(),
);

final exchangeRateCacheProvider = FutureProvider<ExchangeRateCache>((
  ref,
) async {
  return ExchangeRateCache(await SharedPreferences.getInstance());
});

final exchangeRatesProvider =
    AsyncNotifierProvider<ExchangeRatesNotifier, ExchangeRatesSnapshot>(
      ExchangeRatesNotifier.new,
    );

class ExchangeRatesNotifier extends AsyncNotifier<ExchangeRatesSnapshot> {
  static const _freshWait = Duration(seconds: 3);

  @override
  Future<ExchangeRatesSnapshot> build() async {
    final cache = await ref.watch(exchangeRateCacheProvider.future);
    final cached = cache.read();
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading || auth.hasError || auth.value == null) {
      return cached ?? _empty();
    }
    if (cached != null && !isCacheExpired(cached.checkedAt)) return cached;
    return _snapshot(await ref.read(exchangeRepositoryProvider).readRates());
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current?.isRefreshing ?? false) return;
    state = AsyncData((current ?? _empty()).copyWith(isRefreshing: true));
    try {
      final cache = await ref.read(exchangeRateCacheProvider.future);
      final repo = ref.read(exchangeRepositoryProvider);
      final lastSeen =
          current?.latestUpdatedAt ??
          cache.read()?.latestUpdatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final rates = isRateStale(lastSeen)
          ? await _waitForFresh(repo, lastSeen)
          : await repo.readRates();
      final snapshot = _snapshot(rates);
      await cache.write(snapshot);
      state = AsyncData(snapshot);
    } catch (_) {
      state = AsyncData((current ?? _empty()).copyWith(isRefreshing: false));
    }
  }

  Future<List<ExchangeRate>> _waitForFresh(
    ExchangeRepository repo,
    DateTime lastSeen,
  ) async {
    final completer = Completer<List<ExchangeRate>>();
    StreamSubscription<List<ExchangeRate>>? subscription;
    subscription = repo.watchRates().listen(
      (rates) {
        if (rates.isNotEmpty &&
            latestUpdate(rates).isAfter(lastSeen) &&
            !completer.isCompleted) {
          completer.complete(rates);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    try {
      return await completer.future.timeout(
        _freshWait,
        onTimeout: () => repo.readRates(),
      );
    } finally {
      await subscription.cancel();
    }
  }

  ExchangeRatesSnapshot _snapshot(List<ExchangeRate> rates) =>
      ExchangeRatesSnapshot(
        rates: rates,
        checkedAt: DateTime.now().toUtc(),
        latestUpdatedAt: latestUpdate(rates),
      );

  ExchangeRatesSnapshot _empty() => ExchangeRatesSnapshot(
    rates: const [],
    checkedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    latestUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}
