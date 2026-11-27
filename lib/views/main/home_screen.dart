import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, LiquidRoundedSuperellipse;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/exchange/providers/exchange_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';
import 'package:tarlan_bank/views/shared/accounts_strip.dart';
import 'package:tarlan_bank/views/shared/currency_rates_card.dart';
import 'package:tarlan_bank/views/shared/glass_widget_grid.dart';

/// Home screen: reusable widget grid plus Firestore-backed exchange rates.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() => ref.read(exchangeRatesProvider.notifier).refresh();

  void _open(String target) {
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      navigateTo(context, Routes.login);
      return;
    }
    navigateTo(context, target);
  }

  void _openProduct(String type) {
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      navigateTo(context, Routes.login);
      return;
    }
    navigateTo(context, Routes.createAccount, arguments: {'extra': type});
  }

  List<GlassGridItem> _widgets(AppLocalizations l) => [
    GlassGridItem(
      id: 'transfers',
      iconPath: 'assets/icons/ic_transfers.svg',
      title: l.navTransfers,
      onTap: () => _open(Routes.transfers),
    ),
    GlassGridItem(
      id: 'payments',
      iconPath: 'assets/icons/ic_payments.svg',
      title: l.navPayments,
      onTap: () => _open(Routes.payments),
    ),
    GlassGridItem(
      id: 'deposits',
      iconPath: 'assets/icons/ic_deposit.svg',
      title: l.deposits,
      onTap: () => _openProduct('deposit'),
    ),
    GlassGridItem(
      id: 'credits',
      iconPath: 'assets/icons/ic_credit.svg',
      title: l.credits,
      onTap: () => _openProduct('credit'),
    ),
    GlassGridItem(
      id: 'investments',
      iconPath: 'assets/icons/ic_invest.svg',
      title: l.investments,
      onTap: () => _open(Routes.investments),
    ),
    GlassGridItem(
      id: 'agent',
      iconPath: 'assets/icons/ic_chatbot.svg',
      title: l.chatBotName,
      onTap: () => _open(Routes.chatbot),
    ),
  ];

  List<GlassGridItem> _available(AppLocalizations l) => [
    ..._widgets(l),
    GlassGridItem(
      id: 'accounts',
      iconPath: 'assets/icons/ic_accounts.svg',
      title: l.navAccounts,
      onTap: () => _open(Routes.accounts),
    ),
    GlassGridItem(
      id: 'qr',
      iconPath: 'assets/icons/ic_qr.svg',
      title: l.bankQr,
      onTap: () => _open(Routes.qr),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  AccountsStrip(onOpenNew: () => _openProduct('account')),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Text(l.exchangeRates, style: theme.textTheme.titleLarge),
                      GlassContainer(
                        width: double.infinity,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 28,
                        ),
                        padding: const EdgeInsets.all(16),
                        settings: themedGlassSettings(theme),
                        useOwnLayer: false,
                        quality: scrollGlassQuality,
                        child: ratesAsync.when(
                          data: (snapshot) => CurrencyRatesCard(
                            exchangeRates: snapshot.nested,
                            isLoading: snapshot.isRefreshing,
                          ),
                          loading: () => const CurrencyRatesCard(
                            exchangeRates: {},
                            isLoading: true,
                          ),
                          error: (_, _) => const CurrencyRatesCard(
                            exchangeRates: {},
                            isLoading: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GlassWidgetGrid(
                    title: l.widgetsTitle,
                    editLabel: l.widgetsEdit,
                    addLabel: l.widgetsAdd,
                    items: _widgets(l),
                    availableItems: _available(l),
                    rows: 2,
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
