import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:tarlan_bank/models/account_model.dart';
import 'package:tarlan_bank/models/card_model.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../controllers/accounts_controller.dart';
import '../shared/formatters.dart';

class BankCard {
  final int id;
  final String accountNumber; // e.g. "4000123412341234"
  final String name; // user’s full name
  final String cardType; // "card", "deposit", etc.
  final String type; // “VISA Мультивалютная” …
  final String number; // same as accountNumber – kept for legacy UI
  final String? tengeBalance;
  final String? usdBalance;
  final String? euroBalance;
  final String color; // card colour (brand theme)
  final String expiryDate; // e.g. "12/30"
  final String cvv; // **plain CVV** – shown only when the user taps “Show CVV”

  BankCard({
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
    this.expiryDate = "12/30",
    this.cvv = "",
  });
}

class AccountsScreenController extends GetxController {
  final AuthStateService _state = Get.find<AuthStateService>();
  final UserRepository _userRepo = Get.find<UserRepository>();
  late AccountsController _accountsController;

  final RxMap<String, bool> cardFlipStates = <String, bool>{}.obs;
  final RxString visibleCard = ''.obs;

  bool get isLoggedIn => _state.isLoggedIn;

  var currentCard = 0.obs;
  var currentDepositCard = 0.obs;
  var currentCreditCard = 0.obs;

  final RxList<BankCard> cards = <BankCard>[].obs;
  final RxList<BankCard> deposits = <BankCard>[].obs;
  final RxList<BankCard> credits = <BankCard>[].obs;

  @override
  void onInit() {
    super.onInit();
    _accountsController = Get.put(AccountsController());
    ever(_accountsController.accounts, (_) => updateBankCards());
  }

  void fetchAndUpdateCards() async {
    await _accountsController.fetchAccounts();
    updateBankCards();
  }

  void toggleCardFlip(String cardNumber) {
    cardFlipStates[cardNumber] = !(cardFlipStates[cardNumber] ?? false);
  }

  void updateBankCards() {
    cards.clear();
    deposits.clear();
    credits.clear();

    for (AccountModel card in _accountsController.accounts) {
      final bankCard = BankCard(
        id: card.id,
        accountNumber: card.accountNumber,
        name: _userRepo.currentUser?.fullName ?? '',
        cardType: card.accountType,
        type:
            'VISA ${card.accountType == 'card' ? 'Мультивалютная' : card.accountType}',
        number: card.accountNumber,
        tengeBalance: card.currency == 'KZT'
            ? formatCurrency(card.balance, 'KZT', currentLocale.toString())
            : null,
        usdBalance: card.currency == 'USD'
            ? formatCurrency(card.balance, 'USD', currentLocale.toString())
            : null,
        euroBalance: card.currency == 'EUR'
            ? formatCurrency(card.balance, 'EUR', currentLocale.toString())
            : null,
        color: _getCardColor(card.accountType),
        expiryDate:
            '${card.expiryMonth}/${card.expiryYear.toString().substring(2)}',
        cvv: card.cvv ?? '768',
      );

      switch (card.accountType.toLowerCase()) {
        case 'card':
          cards.add(bankCard);
          if (visibleCard.value.isEmpty) visibleCard.value = bankCard.number;
          break;
        case 'deposit':
          deposits.add(bankCard);
          break;
        case 'credit':
          credits.add(bankCard);
          break;
      }
    }
  }

  String _getCardColor(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'credit':
        return 'red';
      case 'deposit':
        return 'gold';
      case 'card':
        return 'primary';
      default:
        return 'primary';
    }
  }

  void onPageChanged(int index, String type) {
    switch (type) {
      case 'card':
        currentCard.value = index % cards.length;
        break;
      case 'deposit':
        currentDepositCard.value = index % deposits.length;
        break;
      case 'credit':
        currentCreditCard.value = index % credits.length;
        break;
    }
  }
}

class AccountsScreen extends StatelessWidget {
  final AccountsScreenController _controller =
      Get.put(AccountsScreenController());

  AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async {
            _controller.fetchAndUpdateCards();
            const timeout = Duration(seconds: 10);
            try {
              await Future.any([
                _controller.cards.stream.timeout(timeout).first,
                _controller.credits.stream.timeout(timeout).first,
                _controller.deposits.stream.timeout(timeout).first,
              ]).timeout(timeout);
              await Future.delayed(const Duration(milliseconds: 300));
            } on TimeoutException {
              print('Refresh operation timed out');
            } catch (e) {
              print('Error during refresh: $e');
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // 1. ADD CENTER AND CONSTRAINED BOX FOR WIDE SCREENS
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 56 + kToolbarHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      CustomCard(
                        label: 'Счета',
                        padding: EdgeInsetsGeometry.all(18),
                      ),
                      Obx(() => _buildCardSection(
                            context: context,
                            cards: _controller.cards,
                            title: 'Карты',
                            size: size,
                            type: 'card',
                            child: ListItem.vertical(
                                svgPath: 'assets/icons/ic_add.svg',
                                title: 'Открыть новую карту',
                                onTap: () {
                                  _controller._state
                                      .setTargetArguments({'extra': 'card'});
                                  Get.toNamed('/createAccount',
                                      arguments: 'card');
                                }),
                          )),
                      Obx(
                        () => _buildCardSection(
                          context: context,
                          cards: _controller.credits,
                          title: 'Кредиты',
                          size: size,
                          type: 'credit',
                          child: ListItem.vertical(
                              svgPath: 'assets/icons/ic_add.svg',
                              title: 'Оформить кредит наличными',
                              subtitle: 'Онлайн до 7 000 000 тенге',
                              onTap: () {
                                _controller._state
                                    .setTargetArguments({'extra': 'credit'});
                                Get.toNamed('/createAccount',
                                    arguments: 'credit');
                              }),
                        ),
                      ),
                      Obx(() => _buildCardSection(
                            context: context,
                            cards: _controller.deposits,
                            title: 'Депозиты',
                            size: size,
                            type: 'deposit',
                            child: ListItem.vertical(
                                svgPath: 'assets/icons/ic_add.svg',
                                title: 'Открыть депозит',
                                subtitle: 'На выгодных условиях',
                                onTap: () {
                                  _controller._state
                                      .setTargetArguments({'extra': 'deposit'});
                                  Get.toNamed('/createAccount',
                                      arguments: 'deposit');
                                }),
                          )),
                      if (!_controller._state.isLoggedIn)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                              color: Colors.black.withValues(alpha: 0.1)),
                        )
                      else
                        const SizedBox.shrink(),
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

  Widget _buildBankCard({
    required BuildContext context,
    required BankCard card,
    Function()? onCardTap,
    Function()? onCardLongPress,
  }) {
    final theme = Theme.of(context);
    final Color colorBg = card.color == 'primary'
        ? theme.colorScheme.tertiary
        : card.color == 'yellow'
            ? theme.extension<Extra>()!.yellowCardBg!
            : card.color == 'gold'
                ? theme.extension<Extra>()!.goldCardBg!
                : card.color == 'purple'
                    ? theme.extension<Extra>()!.purpleCardBg!
                    : card.color == 'red'
                        ? theme.extension<Extra>()!.redCardBg!
                        : theme.extension<Extra>()!.grayCardBg!;

    final Color colorFg = card.color == 'primary'
        ? theme.colorScheme.secondary
        : card.color == 'yellow'
            ? theme.extension<Extra>()!.yellowCardFg!
            : card.color == 'gold'
                ? theme.extension<Extra>()!.goldCardFg!
                : card.color == 'purple'
                    ? theme.extension<Extra>()!.purpleCardFg!
                    : card.color == 'red'
                        ? theme.extension<Extra>()!.redCardFg!
                        : theme.extension<Extra>()!.grayCardFg!;

    return GestureDetector(
      onTap: card.cardType == 'card'
          ? () {
              Get.toNamed('/cardDetails', arguments: card);
            }
          : () {},
      child: Obx(() => TweenAnimationBuilder(
            key: ValueKey(card.number),
            tween: Tween<double>(
              begin: 0,
              end: _controller.cardFlipStates[card.number] ?? false ? 180 : 0,
            ),
            duration: const Duration(milliseconds: 400),
            builder: (context, double value, child) {
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
          )),
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
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: SvgPicture.asset(
                      "assets/icons/visa.svg",
                      width: 50,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ))),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller._userRepo.currentUser?.fullName ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400),
                  ),
                  const Spacer(flex: 5),
                  Text(
                    card.type,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    censorCardNumber(card.number),
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              card.tengeBalance ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              card.usdBalance ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              card.euroBalance ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            )
                          ],
                        ),
                      )
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
    RxString cvv = 'CVV'.obs;
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
                child: Align(
                    alignment: Alignment.bottomRight,
                    child: SvgPicture.asset(
                      "assets/icons/visa.svg",
                      width: 50,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ))),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller._userRepo.currentUser?.fullName ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400),
                  ),
                  const Spacer(flex: 5),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
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
                          icon: Icon(Icons.copy, color: Colors.white),
                          onPressed: () => Clipboard.setData(
                              ClipboardData(text: card.number)),
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
                          padding: EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.2),
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
                                icon: Icon(Icons.copy, color: Colors.white),
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
                            onTap: () {
                              cvv.value = cvv.value == 'CVV' ? card.cvv : 'CVV';
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Obx(() => Text(
                                      cvv.value,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    )),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  bool _getCurrentPage(String type, int index) {
    switch (type) {
      case 'card':
        return _controller.currentCard.value == index;
      case 'credit':
        return _controller.currentCreditCard.value == index;
      case 'deposit':
        return _controller.currentDepositCard.value == index;
      default:
        return false;
    }
  }

  Widget _buildCardSection({
    required BuildContext context,
    required List<BankCard> cards,
    required String title,
    required Size size,
    required String type,
    Function()? onCardTap,
    Function()? onCardLongPress,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return CustomCard(
      label: title,
      labelStyle: theme.textTheme.titleLarge,
      padding: const EdgeInsets.only(top: 16),
      topRowPadding: const EdgeInsets.symmetric(horizontal: 16),
      endWidget: cards.length > 1
          ? Obx(() => Row(
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
              ))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cards.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              // 2. USE LAYOUTBUILDER TO DYNAMICALLY SIZE CARDS & CAP MAX WIDTH
              child: LayoutBuilder(builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final double targetCardWidth = availableWidth * 0.85;
                final double cardWidth =
                    targetCardWidth > 420 ? 420.0 : targetCardWidth;
                final double cardHeight = cardWidth / 1.586;

                return SizedBox(
                  height: cardHeight + 20,
                  child: Swiper(
                    physics: cards.isEmpty
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    loop: false,
                    allowImplicitScrolling: cards.isNotEmpty,
                    itemCount: cards.length,
                    onIndexChanged: (index) {
                      _controller.onPageChanged(index, type);
                      if (type == 'card') {
                        _controller.visibleCard.value = cards[index].number;
                      }
                      for (BankCard card in cards) {
                        if (_controller.cardFlipStates[card.number] == true) {
                          _controller.toggleCardFlip(card.number);
                        }
                      }
                    },
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Center(
                        child: SizedBox(
                          width: cardWidth,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 100),
                            tween: Tween<double>(
                              begin: 0.0,
                              end: _getCurrentPage(type, index) ? 4 : 0,
                            ),
                            builder: (context, elevation, child) {
                              return Material(
                                elevation: elevation,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                child: _buildBankCard(
                                  context: context,
                                  card: card,
                                  onCardTap: () {
                                    _controller._state
                                        .setTargetArguments({'extra': card});
                                    Get.toNamed('/cardDetails');
                                  },
                                  onCardLongPress: onCardLongPress,
                                ),
                              );
                            },
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
              }),
            ),
          ],
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
