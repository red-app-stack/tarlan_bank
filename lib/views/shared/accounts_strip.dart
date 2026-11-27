import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/data/card_model.dart' as data;
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/account_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/selected_card.dart';
import 'package:tarlan_bank/views/shared/section_header.dart';

/// Horizontally scrollable Accounts strip for the top of Home. Tiles are the
/// signed-in user's real Firestore accounts, enriched with linked card
/// instruments; there is no demo data.
class AccountsStrip extends ConsumerWidget {
  const AccountsStrip({super.key, required this.onOpenNew});

  final VoidCallback onOpenNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final accountsAsync = ref.watch(accountsProvider);
    final cardsAsync = ref.watch(cardsProvider);
    final fullName = ref.watch(userProfileProvider).value?.fullName ?? '';

    final accounts =
        accountsAsync.value
            ?.where((a) => a.status == AccountStatus.active)
            .toList() ??
        const <Account>[];
    final cards = cardsAsync.value ?? const [];
    final loading = accountsAsync.isLoading || cardsAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        SectionHeader(
          title: l.navAccounts,
          buttonLabel: l.openNew,
          buttonIcon: 'assets/icons/ic_add.svg',
          onPressed: onOpenNew,
        ),
        SizedBox(
          height: 180,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : accounts.isEmpty
              ? Center(child: Text(l.emptyAccounts, style: _bodyText(context)))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final linkedCard = cards.where(
                      (card) => card.accountId == account.number,
                    );
                    final card = linkedCard.isEmpty ? null : linkedCard.first;
                    final expiry = card != null
                        ? formatCardExpiry(card.expiryMonth, card.expiryYear)
                        : account.depositTerms?.maturityAt != null
                        ? formatShortMonthYear(account.depositTerms!.maturityAt)
                        : '';
                    final last4 = card?.last4 ?? account.number;

                    return AccountCard(
                      imagePath: account.imagePath?.isNotEmpty == true
                          ? account.imagePath!
                          : _fallbackImage(account, card != null),
                      cardType: _typeLabel(account.type, l),
                      balance: account.hideBalance
                          ? null
                          : formatCurrency(
                              account.balance,
                              account.currency,
                              locale,
                            ),
                      showBalance: !account.hideBalance,
                      accountNumber: maskLast4(last4),
                      expiry: expiry,
                      onTap: () {
                        ref
                            .read(selectedCardProvider.notifier)
                            .select(
                              _selectedCard(
                                account,
                                card,
                                fullName,
                                locale,
                                l,
                                expiry,
                              ),
                            );
                        navigateTo(context, Routes.accountsDetails);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  static TextStyle _bodyText(BuildContext context) =>
      (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: 12,
        height: 16 / 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static String _typeLabel(AccountType type, AppLocalizations l) =>
      switch (type) {
        AccountType.current => l.accountCurrent,
        AccountType.deposit => l.accountDeposit,
        AccountType.credit => l.accountCredit,
      };

  static String _fallbackImage(Account account, bool hasCard) {
    final override = account.imagePath;
    if (override != null && override.isNotEmpty) return override;
    if (hasCard) return 'assets/images/accent_image_4.png';
    return switch (account.type) {
      AccountType.current => 'assets/images/accent_image_1.png',
      AccountType.deposit => 'assets/images/accent_image_2.png',
      AccountType.credit => 'assets/images/accent_image_3.png',
    };
  }

  static BankCard _selectedCard(
    Account account,
    data.BankCard? card,
    String fullName,
    String locale,
    AppLocalizations l,
    String expiry,
  ) {
    String? forCurrency(String code) => account.currency == code
        ? formatCurrency(account.balance, code, locale)
        : null;
    return BankCard(
      id: int.tryParse(account.number) ?? 0,
      accountNumber: account.number,
      name: fullName,
      cardType: account.type == AccountType.current
          ? 'card'
          : account.type.name,
      type: account.type == AccountType.current
          ? 'VISA ${l.multiCurrency}'
          : 'VISA ${account.type.name}',
      number: account.number,
      tengeBalance: forCurrency('KZT'),
      usdBalance: forCurrency('USD'),
      euroBalance: forCurrency('EUR'),
      color: switch (account.type) {
        AccountType.credit => 'red',
        AccountType.deposit => 'gold',
        AccountType.current => 'primary',
      },
      expiryDate: expiry,
    );
  }
}
