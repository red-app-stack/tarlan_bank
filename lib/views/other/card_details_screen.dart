// lib/views/main/card_details.dart
import 'package:tarlan_bank/controllers/accounts_controller.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:tarlan_bank/views/main/accounts_screen.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../shared/widgets.dart';
import '../shared/custom_card.dart';
import '../shared/service_item.dart';
import '../shared/list_item.dart';

// Breakpoint at which the two-column wide layout activates.
const double _kWideBreakpoint = 600.0;

// Maximum width the card back will grow to — prevents it looking
// grotesque on a 1400 px desktop screen.
const double _kCardMaxWidth = 420.0;

class CardDetailsScreen extends StatefulWidget {
  const CardDetailsScreen({super.key});

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  final AuthStateService _state = Get.find();
  final UserRepository _userRepo = Get.find();

  late final BankCard card;

  @override
  void initState() {
    super.initState();
    card = Get.arguments as BankCard;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsCtrl = Get.find<AccountsController>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _kWideBreakpoint;
            return isWide
                ? _buildWideLayout(context, theme, accountsCtrl)
                : _buildNarrowLayout(context, theme, accountsCtrl);
          },
        ),
      ),
    );
  }

  // ── Narrow layout (unchanged behaviour) ─────────────────────────────────────

  Widget _buildNarrowLayout(
    BuildContext context,
    ThemeData theme,
    AccountsController accountsCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(context, 'Детали карты'),
                  _buildCardBack(theme, card),
                  _buildBalanceCard(theme, accountsCtrl),
                  _buildStatsRow(theme),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: _buildSettingsList(theme),
                  ),
                  _buildCloseCardButton(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wide layout (two-column) ─────────────────────────────────────────────────

  Widget _buildWideLayout(
    BuildContext context,
    ThemeData theme,
    AccountsController accountsCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildHeader(context, 'Детали карты'),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      // ── Left column: card visual + balance ──────────────────────
                      Expanded(
                        flex: 5,
                        child: Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card capped so it doesn't stretch to 700 px+
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: _kCardMaxWidth),
                                child: _buildCardBack(theme, card),
                              ),
                            ),
                            _buildBalanceCard(theme, accountsCtrl),
                          ],
                        ),
                      ),

                      // ── Right column: stats + settings + close ───────────────────
                      Expanded(
                        flex: 5,
                        child: Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatsRow(theme),
                            CustomCard(
                              padding: EdgeInsets.zero,
                              child: _buildSettingsGrid(theme),
                            ),
                            _buildCloseCardButton(theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared section builders ───────────────────────────────────────────────────

  Widget _buildBalanceCard(ThemeData theme, AccountsController accountsCtrl) {
    return CustomCard(
      label: 'Общий баланс',
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                card.tengeBalance ?? accountsCtrl.getFormattedBalance('KZT'),
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                card.usdBalance ?? accountsCtrl.getFormattedBalance('USD'),
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                card.euroBalance ?? accountsCtrl.getFormattedBalance('EUR'),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Сумма в обработке: 0,00 KZT',
            style: TextStyle(color: Colors.grey),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ServiceItem(
                svgPath: 'assets/icons/ic_deposit.svg',
                label: 'Пополнить',
              ),
              ServiceItem(
                svgPath: 'assets/icons/ic_transfer.svg',
                label: 'Перевести',
              ),
              ServiceItem(
                svgPath: 'assets/icons/ic_withdraw.svg',
                label: 'Снять',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: CustomCard(
            startWidget: SvgPicture.asset('assets/icons/ic_time.svg'),
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Выписка', style: theme.textTheme.titleMedium),
                Text('Доходы и расходы', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Expanded(
          child: CustomCard(
            startWidget: SvgPicture.asset('assets/icons/ic_document.svg'),
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Реквизиты', style: theme.textTheme.titleMedium),
                Text('Номера счетов', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseCardButton(ThemeData theme) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.find<AccountsController>()
              .deleteSingleAccount(card.id.toString()),
          borderRadius: BorderRadius.circular(30),
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              'Закрыть карту',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  // ── Card visual ──────────────────────────────────────────────────────────────

  Widget _buildCardBack(ThemeData theme, BankCard card) {
    RxString cvv = 'CVV'.obs;

    final Color colorBg = switch (card.color) {
      'primary' => theme.colorScheme.tertiary,
      'yellow' => theme.extension<Extra>()!.yellowCardBg!,
      'gold' => theme.extension<Extra>()!.goldCardBg!,
      'purple' => theme.extension<Extra>()!.purpleCardBg!,
      'red' => theme.extension<Extra>()!.redCardBg!,
      _ => theme.extension<Extra>()!.grayCardBg!,
    };

    final Color colorFg = switch (card.color) {
      'primary' => theme.colorScheme.secondary,
      'yellow' => theme.extension<Extra>()!.yellowCardFg!,
      'gold' => theme.extension<Extra>()!.goldCardFg!,
      'purple' => theme.extension<Extra>()!.purpleCardFg!,
      'red' => theme.extension<Extra>()!.redCardFg!,
      _ => theme.extension<Extra>()!.grayCardFg!,
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
                    _userRepo.currentUser?.fullName ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(flex: 5),
                  // Card number row
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
                              ClipboardData(text: card.number)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Expiry + CVV row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.only(left: 12),
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
                                icon:
                                    const Icon(Icons.copy, color: Colors.white),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Obx(
                                () => Text(
                                  cvv.value,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
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
}

// ── Settings list (narrow: vertical list) ────────────────────────────────────

Widget _buildSettingsList(ThemeData theme) {
  return Column(
    spacing: 8,
    children: _settingsItems.entries
        .map((e) => ListItem.vertical(
              svgPath: e.value,
              title: e.key,
              onTap: () {},
            ))
        .toList(),
  );
}

// ── Settings grid (wide: 2-column grid) ──────────────────────────────────────

Widget _buildSettingsGrid(ThemeData theme) {
  final entries = _settingsItems.entries.toList();
  // Pair them up: [0,1], [2,3], [4,5], [6,7]
  final List<Widget> rows = [];
  for (int i = 0; i < entries.length; i += 2) {
    final bool isLast = i + 1 >= entries.length;
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

// ── Shared data ───────────────────────────────────────────────────────────────

const Map<String, String> _settingsItems = {
  'Переименовать карту': 'assets/icons/ic_edit.svg',
  'Управление подписками': 'assets/icons/ic_subscriptions.svg',
  'Заказать карту': 'assets/icons/ic_card.svg',
  'Установить лимиты': 'assets/icons/ic_limits.svg',
  'Получить справку': 'assets/icons/ic_document.svg',
  'Блокировки': 'assets/icons/ic_lock.svg',
  'Google Pay': 'assets/icons/ic_google_pay.svg',
  'Настройки карты': 'assets/icons/ic_settings.svg',
};
