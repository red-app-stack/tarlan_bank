import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/section_header.dart';

/// Title-only section at the top of Home showing the user's total funds on
/// debit accounts. Deposits are savings and credit balances are
/// debt, so neither counts as debit money.
class DebitBalance extends ConsumerWidget {
  const DebitBalance({super.key});

  /// Amount and display currency of the active debit accounts. Mixed
  /// currencies are not converted here: the first account sets the currency.
  static ({double amount, String currency}) totals(List<Account> accounts) {
    final debit = accounts
        .where(
          (a) =>
              a.type == AccountType.debit && a.status == AccountStatus.active,
        )
        .toList();
    if (debit.isEmpty) return (amount: 0, currency: 'KZT');
    return (
      amount: debit.fold<double>(0, (sum, a) => sum + a.balance),
      currency: debit.first.currency,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final balance = totals(accounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        SectionHeader(title: l.debitBalance),
        Text(
          formatCurrency(balance.amount, balance.currency, locale),
          style: (theme.textTheme.displayMedium ?? const TextStyle()).copyWith(
            fontSize: 32,
            height: 36 / 32,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
