import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/core/utils/phone_number.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart'
    show BankTransaction, TransactionType;
import 'package:tarlan_bank/features/transactions/providers/transactions_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/list_item.dart';
import 'package:tarlan_bank/views/shared/shared_classes.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';

/// Profile overview from `users/{uid}`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _typeLabel(AppLocalizations l, TransactionType type) => switch (type) {
    TransactionType.deposit => l.auTxDeposit,
    TransactionType.withdrawal => l.auTxWithdrawal,
    TransactionType.phoneTransfer => l.auTxPhoneTransfer,
    TransactionType.qrTransfer => l.auTxQrTransfer,
    TransactionType.currencyConversion => l.auTxCurrencyConversion,
    TransactionType.internalTransfer => l.auTxInternalTransfer,
    TransactionType.cardTransfer => l.auTxCardTransfer,
    TransactionType.swiftTransfer => l.auTxSwiftTransfer,
  };

  String _description(AppLocalizations l, BankTransaction? tx, String empty) {
    if (tx == null) return empty;
    return '${_typeLabel(l, tx.type)} ${formatCurrency(tx.amount, tx.currency, 'RU')}';
  }

  List<MenuSection> _sections(
    AppLocalizations l,
    List<BankTransaction> txs,
    String phone,
  ) {
    bool isOneOf(BankTransaction tx, Set<String> types) =>
        types.contains(tx.type.wireName);

    final accountOperations = txs.where(
      (tx) => isOneOf(tx, {
        'deposit',
        'withdrawal',
        'currency_conversion',
        'internal_transfer',
      }),
    );
    final transferOperations = txs.where(
      (tx) =>
          isOneOf(tx, {'phone_transfer', 'card_transfer', 'swift_transfer'}),
    );
    final paymentOperations = txs.where(
      (tx) => tx.type.wireName == 'qr_transfer',
    );

    return [
      MenuSection(
        title: l.auMyNotifications,
        items: [
          MenuItem(
            icon: 'assets/icons/ic_transactions.svg',
            title: l.auAccountOperations,
            description: _description(
              l,
              accountOperations.isEmpty ? null : accountOperations.first,
              l.auNoOperations,
            ),
            routeArg: Routes.transfersHistory,
          ),
          MenuItem(
            icon: 'assets/icons/ic_transfers.svg',
            title: l.navTransfers,
            description: _description(
              l,
              transferOperations.isEmpty ? null : transferOperations.first,
              l.auNoTransfers,
            ),
            routeArg: Routes.transfersHistory,
          ),
          MenuItem(
            icon: 'assets/icons/ic_payments.svg',
            title: l.navPayments,
            description: _description(
              l,
              paymentOperations.isEmpty ? null : paymentOperations.first,
              l.auNoPayments,
            ),
            routeArg: Routes.paymentsHistory,
          ),
          MenuItem(
            icon: 'assets/icons/ic_security.svg',
            title: l.securitySettings,
            description: l.auSecurityTip,
          ),
        ],
      ),
      MenuSection(
        title: l.auSettingsTitle,
        items: [
          MenuItem(
            icon: 'assets/icons/ic_notifications.svg',
            title: l.auNotificationsTitle,
          ),
          MenuItem(
            icon: 'assets/icons/ic_language.svg',
            title: l.auAppLanguage,
          ),
          MenuItem(
            icon: 'assets/icons/ic_smartphone.svg',
            title: phone.isEmpty ? l.phone : phone,
            description: l.auTrustedPhone,
          ),
          MenuItem(
            icon: 'assets/icons/ic_phone.svg',
            title: l.auPhoneTransfers,
          ),
        ],
      ),
    ];
  }

  bool showNotification(String icon) => false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);
    final txsAsync = ref.watch(transactionsHistoryProvider(null));
    final txs = txsAsync.value ?? const <BankTransaction>[];
    final profile = ref.watch(userProfileProvider).value;
    final authUser = ref.watch(currentUserProvider);
    final fullName = profile?.fullName ?? authUser?.email ?? l.unknown;
    final phone = formatDisplayPhone(profile?.phoneNumber ?? '');
    final photoUrl = profile?.photoUrl ?? '';
    final sections = _sections(l, txs, phone);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: buildHeader(context, l.auProfileTitle),
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(transactionsHistoryProvider(null));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 56 + kToolbarHeight,
              ),
              child: Column(
                spacing: 16,
                children: [
                  SizedBox(
                    width: size.width / 2,
                    child: CustomCard(
                      crossAxisAlignment: .center,
                      child: buildUserCard(
                        fullName,
                        theme,
                        size,
                        photoUrl: photoUrl,
                      ),
                    ),
                  ),
                  ...sections.map(
                    (section) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomCard(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          topRowPadding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                          ),
                          label: section.title,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...section.items.map(
                                (item) => ListItem.vertical(
                                  svgPath: item.icon,
                                  title: item.title,
                                  subtitle: item.description,
                                  showNotification: showNotification(item.icon),
                                  onTap: item.routeArg is String
                                      ? () => context.go(item.routeArg!)
                                      : () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
