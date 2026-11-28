import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/shared/selected_card.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

const double _kWideBreakpoint = 600.0;
const double _kCardMaxWidth = 420.0;

class CardDetailsScreen extends ConsumerStatefulWidget {
  const CardDetailsScreen({super.key, this.card});

  /// The router opens this route without arguments; `null` renders an empty
  /// state instead of throwing (see [legacyArguments] removal).
  final BankCard? card;

  @override
  ConsumerState<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends ConsumerState<CardDetailsScreen> {
  final Set<String> _visibleCvv = <String>{};

  Future<void> _closeCard(BankCard card) async {
    try {
      await ref
          .read(accountsRepositoryProvider)
          .closeAccount(card.accountNumber);
      ref.invalidate(accountsProvider);
      if (mounted) navigateBack();
    } on AppFailure {
      // Keep the card visible on failure; the error is surfaced by the shell.
    }
  }

  Map<String, String> _settings(AppLocalizations l) => {
    l.renameCard: AppIcons.edit,
    l.manageSubscriptions: AppIcons.subscriptions,
    l.orderCard: AppIcons.card,
    l.setLimits: AppIcons.limits,
    l.getCertificate: AppIcons.document,
    l.blocks: AppIcons.lock,
    'Google Pay': AppIcons.googlePay,
    l.cardSettings: AppIcons.settings,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final card = widget.card ?? ref.watch(selectedCardProvider);
    if (card == null) {
      return Scaffold(
        appBar: buildHeader(context, l.cardDetails),
        body: SafeArea(child: _emptyState(l.cardDetailsEmpty)),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _kWideBreakpoint;
            return isWide
                ? _buildWideLayout(context, theme, card, l)
                : _buildNarrowLayout(context, theme, card, l);
          },
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppIcons.emptyList,
            height: size.height * 0.18,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.secondaryContainer,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    ThemeData theme,
    BankCard card,
    AppLocalizations l,
  ) {
    return Padding(
      padding: screenPadding,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(context, l.cardDetails),
                  _buildCardBack(theme, card),
                  _buildBalanceCard(theme, card, l),
                  _buildStatsRow(theme, l),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: _buildSettingsList(theme, l),
                  ),
                  _buildCloseCardButton(theme, card, l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    ThemeData theme,
    BankCard card,
    AppLocalizations l,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildHeader(context, l.cardDetails),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _kCardMaxWidth,
                            ),
                            child: _buildCardBack(theme, card),
                          ),
                        ),
                        _buildBalanceCard(theme, card, l),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatsRow(theme, l),
                        CustomCard(
                          padding: EdgeInsets.zero,
                          child: _buildSettingsGrid(theme, l),
                        ),
                        _buildCloseCardButton(theme, card, l),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _balanceFor(BankCard card, String currency) {
    switch (currency) {
      case 'KZT':
        return card.tengeBalance ?? '';
      case 'USD':
        return card.usdBalance ?? '';
      case 'EUR':
        return card.euroBalance ?? '';
      default:
        return '';
    }
  }

  Widget _buildBalanceCard(ThemeData theme, BankCard card, AppLocalizations l) {
    final locale = Localizations.localeOf(context).toString();
    final accounts = ref.watch(accountsProvider).value ?? const [];
    String total(String currency) {
      final own = _balanceFor(card, currency);
      if (own.isNotEmpty) return own;
      final sum = accounts
          .where((a) => a.currency == currency)
          .fold<double>(0, (s, a) => s + a.balance);
      return formatCurrency(sum, currency, locale);
    }

    return CustomCard(
      label: l.totalBalance,
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(total('KZT'), style: const TextStyle(fontSize: 18)),
              Text(total('USD'), style: const TextStyle(fontSize: 18)),
              Text(total('EUR'), style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.pendingAmount,
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ServiceItem(svgPath: AppIcons.deposits, label: l.topUp),
              ServiceItem(svgPath: AppIcons.transfer, label: l.transfer),
              ServiceItem(svgPath: AppIcons.withdraw, label: l.withdraw),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, AppLocalizations l) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: CustomCard(
            startWidget: SvgPicture.asset(AppIcons.time),
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.statement, style: theme.textTheme.titleMedium),
                Text(l.incomeExpenses, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Expanded(
          child: CustomCard(
            startWidget: SvgPicture.asset(AppIcons.document),
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.requisites, style: theme.textTheme.titleMedium),
                Text(l.accountNumbers, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseCardButton(
    ThemeData theme,
    BankCard card,
    AppLocalizations l,
  ) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _closeCard(card),
          borderRadius: BorderRadius.circular(30),
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              l.closeCard,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack(ThemeData theme, BankCard card) {
    final showCvv = _visibleCvv.contains(card.number);
    final colorBg = switch (card.color) {
      'primary' => theme.colorScheme.tertiary,
      'gold' => theme.extension<Extra>()!.goldCardBg!,
      'red' => theme.extension<Extra>()!.redCardBg!,
      _ => theme.extension<Extra>()!.grayCardBg!,
    };
    return Container(
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Stack(
          children: [
            Positioned(
              bottom: 28,
              right: 28,
              child: SvgPicture.asset(
                AppIcons.visa,
                width: 50,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(flex: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          formatCardNumber(card.number),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: card.number),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                card.expiryDate,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                ),
                                onPressed: () => Clipboard.setData(
                                  ClipboardData(text: card.expiryDate),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (showCvv) {
                              _visibleCvv.remove(card.number);
                            } else {
                              _visibleCvv.add(card.number);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                showCvv ? card.cvv : 'CVV',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(ThemeData theme, AppLocalizations l) {
    return Column(
      spacing: 8,
      children: _settings(l).entries
          .map(
            (e) =>
                ListItem.vertical(svgPath: e.value, title: e.key, onTap: () {}),
          )
          .toList(),
    );
  }

  Widget _buildSettingsGrid(ThemeData theme, AppLocalizations l) {
    final entries = _settings(l).entries.toList();
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final isLast = i + 1 >= entries.length;
      rows.add(
        Row(
          children: [
            Expanded(
              child: ListItem.vertical(
                svgPath: entries[i].value,
                title: entries[i].key,
                onTap: () {},
              ),
            ),
            if (!isLast)
              Expanded(
                child: ListItem.vertical(
                  svgPath: entries[i + 1].value,
                  title: entries[i + 1].key,
                  onTap: () {},
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
    }
    return Column(spacing: 8, children: rows);
  }
}
