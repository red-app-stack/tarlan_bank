import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:card_swiper/card_swiper.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';

/// View model for the card swiper. Cards are instruments derived from the
/// Firestore [Account] ledger — no CVV is ever stored or displayed.
class BankCard {
  const BankCard({
    required this.id,
    required this.accountNumber,
    required this.name,
    required this.cardType,
    required this.type,
    required this.number,
    required this.tengeBalance,
    required this.usdBalance,
    required this.euroBalance,
    required this.color,
    this.expiryDate = '12/30',
    this.cvv = '',
  });

  final int id;
  final String accountNumber;
  final String name;
  final String cardType;
  final String type;
  final String number;
  final String? tengeBalance;
  final String? usdBalance;
  final String? euroBalance;
  final String color;
  final String expiryDate;
  final String cvv;
}

/// Last card opened from the accounts branch; read by CardDetailsScreen.
class SelectedCardNotifier extends Notifier<BankCard?> {
  @override
  BankCard? build() => null;

  void select(BankCard? card) => state = card;
}

final selectedCardProvider = NotifierProvider<SelectedCardNotifier, BankCard?>(
  SelectedCardNotifier.new,
);

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final Map<String, bool> _cardFlipStates = <String, bool>{};
  final Set<String> _visibleCvv = <String>{};
  int _currentCard = 0;
  int _currentCreditCard = 0;
  int _currentDepositCard = 0;
  String _visibleCard = '';

  Future<void> _refresh() async {
    ref.invalidate(accountsProvider);
    ref.invalidate(userProfileProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _onPageChanged(int index, List<BankCard> cards, String type) {
    if (cards.isEmpty) return;
    setState(() {
      final page = index % cards.length;
      switch (type) {
        case 'card':
          _currentCard = page;
          _visibleCard = cards[page].number;
        case 'credit':
          _currentCreditCard = page;
        case 'deposit':
          _currentDepositCard = page;
      }
      for (final card in cards) {
        _cardFlipStates[card.number] = false;
      }
    });
  }

  BankCard _toBankCard(
    Account account,
    String fullName,
    String locale,
    AppLocalizations l,
  ) {
    final isCurrent = account.type == AccountType.current;
    final typeKey = isCurrent ? 'card' : account.type.name;
    return BankCard(
      id: int.tryParse(account.number) ?? 0,
      accountNumber: account.number,
      name: fullName,
      cardType: typeKey,
      type: isCurrent ? 'VISA ${l.multiCurrency}' : 'VISA ${account.type.name}',
      number: account.number,
      tengeBalance: account.currency == 'KZT'
          ? formatCurrency(account.balance, 'KZT', locale)
          : null,
      usdBalance: account.currency == 'USD'
          ? formatCurrency(account.balance, 'USD', locale)
          : null,
      euroBalance: account.currency == 'EUR'
          ? formatCurrency(account.balance, 'EUR', locale)
          : null,
      color: switch (account.type) {
        AccountType.credit => 'red',
        AccountType.deposit => 'gold',
        AccountType.current => 'primary',
      },
    );
  }

  void _openProduct(String type) =>
      navigateTo(context, Routes.accountsCreate, arguments: {'extra': type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final locale = Localizations.localeOf(context).toString();
    final l = AppLocalizations.of(context);

    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).value;
    final fullName = profile?.fullName ?? '';
    final accountsAsync = ref.watch(accountsProvider);
    final isGuest = user == null || user.isAnonymous;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 56 + kToolbarHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      CustomCard(
                        label: l.navAccounts,
                        padding: EdgeInsetsGeometry.all(18),
                      ),
                      accountsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => _buildEmptyState(l, size, theme),
                        data: (accounts) {
                          if (isGuest || accounts.isEmpty) {
                            return _buildEmptyState(l, size, theme);
                          }
                          final cards = <BankCard>[];
                          final deposits = <BankCard>[];
                          final credits = <BankCard>[];
                          for (final account in accounts) {
                            final card = _toBankCard(
                              account,
                              fullName,
                              locale,
                              l,
                            );
                            switch (account.type) {
                              case AccountType.current:
                                cards.add(card);
                              case AccountType.deposit:
                                deposits.add(card);
                              case AccountType.credit:
                                credits.add(card);
                            }
                          }
                          if (_visibleCard.isEmpty && cards.isNotEmpty) {
                            _visibleCard = cards.first.number;
                          }
                          return Column(
                            spacing: 16,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardSection(
                                context: context,
                                cards: cards,
                                title: l.cards,
                                size: size,
                                type: 'card',
                                child: ListItem.vertical(
                                  svgPath: 'assets/icons/ic_add.svg',
                                  title: l.openNewCard,
                                  onTap: () => _openProduct('card'),
                                ),
                              ),
                              _buildCardSection(
                                context: context,
                                cards: credits,
                                title: l.credits,
                                size: size,
                                type: 'credit',
                                child: ListItem.vertical(
                                  svgPath: 'assets/icons/ic_add.svg',
                                  title: l.creditCash,
                                  subtitle: l.creditCashSubtitle,
                                  onTap: () => _openProduct('credit'),
                                ),
                              ),
                              _buildCardSection(
                                context: context,
                                cards: deposits,
                                title: l.deposits,
                                size: size,
                                type: 'deposit',
                                child: ListItem.vertical(
                                  svgPath: 'assets/icons/ic_add.svg',
                                  title: l.openProduct(l.createDeposit),
                                  subtitle: l.openDepositSubtitle,
                                  onTap: () => _openProduct('deposit'),
                                ),
                              ),
                              if (isGuest)
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                            ],
                          );
                        },
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

  Widget _buildEmptyState(AppLocalizations l, Size size, ThemeData theme) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: size.height * 0.12),
        child: Center(
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_empty_list.svg',
                height: size.height * 0.18,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.secondaryContainer,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              Text(l.emptyAccounts, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );

  Widget _buildBankCard({
    required BuildContext context,
    required BankCard card,
  }) {
    final theme = Theme.of(context);
    final colorBg = switch (card.color) {
      'primary' => theme.colorScheme.tertiary,
      'gold' => theme.extension<Extra>()!.goldCardBg!,
      'red' => theme.extension<Extra>()!.redCardBg!,
      _ => theme.extension<Extra>()!.grayCardBg!,
    };
    final colorFg = switch (card.color) {
      'primary' => theme.colorScheme.secondary,
      'gold' => theme.extension<Extra>()!.goldCardFg!,
      'red' => theme.extension<Extra>()!.redCardFg!,
      _ => theme.extension<Extra>()!.grayCardFg!,
    };

    return GestureDetector(
      onTap: () {
        ref.read(selectedCardProvider.notifier).select(card);
        navigateTo(context, Routes.accountsDetails);
      },
      child: TweenAnimationBuilder<double>(
        key: ValueKey(card.number),
        tween: Tween<double>(
          begin: 0,
          end: _cardFlipStates[card.number] == true ? 180 : 0,
        ),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value * pi / 180),
            child: value < 90
                ? _buildCardFront(theme, card, colorBg, colorFg)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardBack(theme, card, colorBg, colorFg),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(
    ThemeData theme,
    BankCard card,
    Color colorBg,
    Color colorFg,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorFg, colorBg],
        ),
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
                'assets/icons/visa.svg',
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
                  Text(
                    card.type,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    censorCardNumber(card.number),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      for (final balance in [
                        card.tengeBalance,
                        card.usdBalance,
                        card.euroBalance,
                      ])
                        if (balance != null)
                          Text(
                            balance,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(
    ThemeData theme,
    BankCard card,
    Color colorBg,
    Color colorFg,
  ) {
    final showCvv = _visibleCvv.contains(card.number);
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
                'assets/icons/visa.svg',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _getCurrentPage(String type, int index) => switch (type) {
    'card' => _currentCard == index,
    'credit' => _currentCreditCard == index,
    'deposit' => _currentDepositCard == index,
    _ => false,
  };

  Widget _buildCardSection({
    required BuildContext context,
    required List<BankCard> cards,
    required String title,
    required Size size,
    required String type,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return CustomCard(
      label: title,
      labelStyle: theme.textTheme.titleLarge,
      padding: const EdgeInsets.only(top: 16),
      topRowPadding: const EdgeInsets.symmetric(horizontal: 16),
      endWidget: cards.length > 1
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                cards.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: _getCurrentPage(type, index) ? 16 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getCurrentPage(type, index)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final target = constraints.maxWidth * 0.85;
                  final cardWidth = target > 420 ? 420.0 : target;
                  final cardHeight = cardWidth / 1.586;
                  return SizedBox(
                    height: cardHeight + 20,
                    child: Swiper(
                      loop: false,
                      allowImplicitScrolling: true,
                      itemCount: cards.length,
                      onIndexChanged: (index) =>
                          _onPageChanged(index, cards, type),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 100),
                              tween: Tween<double>(
                                begin: 0,
                                end: _getCurrentPage(type, index) ? 4 : 0,
                              ),
                              builder: (context, elevation, child) => Material(
                                elevation: elevation,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: _buildBankCard(
                                  context: context,
                                  card: card,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      layout: SwiperLayout.TINDER,
                      itemWidth: cardWidth,
                      itemHeight: cardHeight,
                      scale: 0.5,
                      viewportFraction: 0.5,
                      curve: Curves.easeInOut,
                      duration: 400,
                    ),
                  );
                },
              ),
            ),
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
