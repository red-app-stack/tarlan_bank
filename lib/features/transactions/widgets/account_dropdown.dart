import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';

/// Account picker used by the transfer screens. Mirrors the legacy
/// `AnimatedCardDropdown` but is wired to the remodeled Firestore [Account]
/// (no GetX, no REST-shaped `AccountModel`).
class TransferAccountDropdown extends StatelessWidget {
  const TransferAccountDropdown({
    super.key,
    required this.accounts,
    required this.label,
    required this.selectedAccount,
    required this.isExpanded,
    required this.onAccountSelected,
    required this.onToggle,
  });

  final List<Account> accounts;
  final String label;
  final Account? selectedAccount;
  final bool isExpanded;
  final Function(Account) onAccountSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            splashFactory: InkRipple.splashFactory,
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
            child: Row(
              children: [
                Text(label, style: theme.textTheme.titleLarge),
                const Spacer(),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            child: AnimatedCrossFade(
              firstChild: selectedAccount != null
                  ? _AccountItem(
                      account: selectedAccount!,
                      theme: theme,
                      isSelected: true,
                      onTap: onToggle,
                    )
                  : const SizedBox.shrink(),
              secondChild: Column(
                children: accounts
                    .map(
                      (account) => _AccountItem(
                        account: account,
                        theme: theme,
                        isSelected: account.number == selectedAccount?.number,
                        onTap: () => onAccountSelected(account),
                      ),
                    )
                    .toList(),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.account,
    required this.theme,
    required this.isSelected,
    this.onTap,
  });

  final Account account;
  final ThemeData theme;
  final bool isSelected;
  final VoidCallback? onTap;

  String _typeLabel(AppLocalizations l) => switch (account.type) {
    AccountType.debit => l.accountDebit,
    AccountType.deposit => l.accountDeposit,
    AccountType.credit => l.accountCredit,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashFactory: InkRipple.splashFactory,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppIcons.card,
                  width: 36,
                  height: 36,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_typeLabel(l), style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        censorCardNumber(account.number),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(account.balance, account.currency, 'ru_RU'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
