import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassBatch, LiquidGlassLens, LiquidGlassShape;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/exchange/providers/exchange_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';
import 'package:tarlan_bank/views/shared/accounts_strip.dart';
import 'package:tarlan_bank/views/shared/currency_rates_card.dart';
import 'package:tarlan_bank/views/shared/debit_balance.dart';
import 'package:tarlan_bank/views/shared/glass_widget_grid.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';
import 'package:tarlan_bank/views/shared/section_header.dart';

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
      iconPath: AppIcons.transfers,
      title: l.navTransfers,
      onTap: () => _open(Routes.transfers),
    ),
    GlassGridItem(
      id: 'payments',
      iconPath: AppIcons.payments,
      title: l.navPayments,
      onTap: () => _open(Routes.payments),
    ),
    GlassGridItem(
      id: 'deposits',
      iconPath: AppIcons.deposits,
      title: l.deposits,
      onTap: () => _openProduct('deposit'),
    ),
    GlassGridItem(
      id: 'credits',
      iconPath: AppIcons.credits,
      title: l.credits,
      onTap: () => _openProduct('credit'),
    ),
    GlassGridItem(
      id: 'investments',
      iconPath: AppIcons.investments,
      title: l.investments,
      onTap: () => _open(Routes.investments),
    ),
    GlassGridItem(
      id: 'agent',
      iconPath: AppIcons.aiAgent,
      title: l.chatBotName,
      onTap: () => _open(Routes.chatbot),
    ),
  ];

  List<GlassGridItem> _available(AppLocalizations l) => [
    ..._widgets(l),
    GlassGridItem(
      id: 'accounts',
      iconPath: AppIcons.accounts,
      title: l.navAccounts,
      onTap: () => _open(Routes.accounts),
    ),
    GlassGridItem(
      id: 'qr',
      iconPath: AppIcons.qr,
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
          // edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: _refresh,
          // One batch for the page: every lens below shares a single read.
          // The shell chrome stays outside it so it refracts the page.
          child: LiquidGlassBatch(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(overscroll: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  // MainShell supplies the 32/16 inset; only the floating top
                  // bar needs extra clearance here.
                  padding: const EdgeInsets.only(
                    top: shellTopBarExtraTop,
                    bottom: kBottomNavigationBarHeight * 2,
                  ),
                  child: Column(
                    spacing: 24,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DebitBalance(),
                      AccountsStrip(onOpenNew: () => _openProduct('account')),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          SectionHeader(title: l.exchangeRates),
                          SizedBox(
                            width: double.infinity,
                            child: LiquidGlassLens(
                              style: themedGlassStyle(
                                theme,
                                shape: const LiquidGlassShape.squircle(
                                  cornerRadius: 28,
                                ),
                                blur: scrollGlassBlur,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}
