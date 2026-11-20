import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/exchange/providers/exchange_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/routes/app_routes.dart' show Routes;
import 'package:tarlan_bank/views/shared/currency_rates_card.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';

import '../shared/custom_card.dart';

/// Home migrated to Riverpod: no GetX controller, no JWT-dependent rates.
/// Exchange rates come from the Firestore cache (readable by guests too).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<ServiceItemData> _services(AppLocalizations l) => [
    ServiceItemData('assets/images/creditcard.png', l.cards, 'card'),
    ServiceItemData('assets/images/deposit.png', l.deposits, 'deposit'),
    ServiceItemData('assets/images/credit.png', l.credits, 'credit'),
    ServiceItemData('assets/images/installment.png', l.installment, 'transfer'),
    ServiceItemData(
      'assets/images/investments.png',
      l.investments,
      Routes.investments,
    ),
  ];

  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ref.read(exchangeRepositoryProvider).fetchRates();
    } on AppFailure {
      // Cached values stay visible; no raw error is shown (offline UX).
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _onServiceTap(ServiceItemData service) {
    if (service.routeArg == Routes.investments) {
      navigateTo(context, Routes.investments);
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      // Guests browse main/menu/rates; products require a full account.
      navigateTo(context, Routes.login);
    } else {
      navigateTo(
        context,
        Routes.createAccount,
        arguments: {'extra': service.routeArg},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final services = _services(l);
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 56 + kToolbarHeight,
              ),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomCard(label: l.home, padding: const EdgeInsets.all(18)),
                  CustomCard(
                    padding: const EdgeInsets.all(0),
                    child: SizedBox(
                      height: 128,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: services.length,
                        itemExtent: 100,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          return ServiceItem(
                            imagePath: service.iconPath,
                            label: service.label,
                            iconSize: 120 * 0.6,
                            expanded: false,
                            onTap: () => _onServiceTap(service),
                          );
                        },
                      ),
                    ),
                  ),
                  CustomCard(
                    label: l.exchangeRates,
                    labelStyle: theme.textTheme.titleLarge,
                    child: ratesAsync.when(
                      data: (rates) => CurrencyRatesCard(
                        exchangeRates: rates,
                        isLoading: false,
                      ),
                      loading: () => const CurrencyRatesCard(
                        exchangeRates: {},
                        isLoading: true,
                      ),
                      error: (_, _) => CurrencyRatesCard(
                        exchangeRates: const {},
                        isLoading: _refreshing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
