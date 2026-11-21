import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';
import 'package:tarlan_bank/features/transactions/providers/transactions_providers.dart';
import 'package:tarlan_bank/features/transactions/providers/transfer_ui_providers.dart';
import 'package:tarlan_bank/features/transactions/widgets/account_dropdown.dart';
import 'package:tarlan_bank/features/transactions/widgets/transfer_header.dart';
import 'package:tarlan_bank/features/transactions/widgets/transfer_amount_controller.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/amount_input.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';

class SelfTransferScreen extends ConsumerStatefulWidget {
  const SelfTransferScreen({super.key, this.transaction});

  /// Optional prefill; null is handled gracefully (empty form).
  final BankTransaction? transaction;

  @override
  ConsumerState<SelfTransferScreen> createState() => _SelfTransferScreenState();
}

class _SelfTransferScreenState extends ConsumerState<SelfTransferScreen> {
  final TransferAmountController amountCtl = TransferAmountController();

  Account? selectedAccount;
  Account? selectedDestinationAccount;
  bool isAccountDropdownExpanded = false;
  bool isDestinationDropdownExpanded = false;
  String? _pendingDestination;
  bool _initialized = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    amountCtl.initialize();
    final initial = widget.transaction ?? ref.read(selectedTransactionProvider);
    ref.read(selectedTransactionProvider.notifier).clear();
    if (initial != null) {
      if (initial.amount > 0) {
        amountCtl.update(initial.amount.toString(), () {});
      }
      _pendingDestination = initial.toAccountId;
    }
  }

  @override
  void dispose() {
    amountCtl.dispose();
    super.dispose();
  }

  List<Account> _sourceAccounts(List<Account> all) {
    final current =
        all
            .where(
              (a) =>
                  a.type == AccountType.current &&
                  a.status == AccountStatus.active,
            )
            .toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));
    return current;
  }

  List<Account> _destinationAccounts(List<Account> all) =>
      all.where((a) => a.number != selectedAccount?.number).toList();

  void _syncSelection(List<Account> accounts) {
    final source = _sourceAccounts(accounts);
    final sourceChanged = source.isEmpty
        ? selectedAccount != null
        : selectedAccount == null ||
              !source.any((a) => a.number == selectedAccount!.number);
    if (sourceChanged) {
      setState(() => selectedAccount = source.isEmpty ? null : source.first);
    }

    final destinations = _destinationAccounts(accounts);
    Account? destination;
    if (_pendingDestination != null) {
      for (final account in destinations) {
        if (account.number == _pendingDestination) {
          destination = account;
          break;
        }
      }
      _pendingDestination = null;
    }
    if (destination == null &&
        (selectedDestinationAccount == null ||
            !destinations.any(
              (a) => a.number == selectedDestinationAccount!.number,
            ))) {
      destination = destinations.isEmpty ? null : destinations.first;
    }
    if (destination != null && destination != selectedDestinationAccount) {
      setState(() => selectedDestinationAccount = destination);
    }
  }

  Future<void> _submit(AppLocalizations l) async {
    if (_submitting) return;
    if (selectedAccount == null || selectedDestinationAccount == null) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: selectedAccount == null
            ? l.errorSelectCard
            : l.recipientNotFound,
      );
      return;
    }
    if (amountCtl.isEmpty) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.errorEnterAmount,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final tx = await ref
          .read(transactionsRepositoryProvider)
          .createTransaction(
            fromAccountId: selectedAccount!.number,
            toAccountId: selectedDestinationAccount!.number,
            amount: amountCtl.parsed,
            currency: selectedAccount!.currency,
            type: TransactionType.internalTransfer,
          );
      ref.read(selectedTransactionProvider.notifier).select(tx);
      ref.invalidate(transactionsHistoryProvider);
      ref.invalidate(accountsProvider);
      if (mounted) context.go(Routes.transfersDetails);
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.success,
          message: l.transferSuccess,
        );
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: l.transferFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final source = _sourceAccounts(accounts);
    final destinations = _destinationAccounts(accounts);

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelection(accounts);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              buildTransferHeader(context, l.ownAccounts),
              SizedBox(height: size.height * 0.02),
              Expanded(
                child: RefreshIndicator(
                  edgeOffset: MediaQuery.of(context).padding.top,
                  onRefresh: () async {
                    ref.invalidate(accountsProvider);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelector(
                          theme,
                          l,
                          l.from,
                          source,
                          selectedAccount,
                          isAccountDropdownExpanded,
                          (account) => setState(() {
                            selectedAccount = account;
                            isAccountDropdownExpanded = false;
                          }),
                          () => setState(
                            () => isAccountDropdownExpanded =
                                !isAccountDropdownExpanded,
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        _buildSelector(
                          theme,
                          l,
                          l.to,
                          destinations,
                          selectedDestinationAccount,
                          isDestinationDropdownExpanded,
                          (account) => setState(() {
                            selectedDestinationAccount = account;
                            isDestinationDropdownExpanded = false;
                          }),
                          () => setState(
                            () => isDestinationDropdownExpanded =
                                !isDestinationDropdownExpanded,
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        _buildAmountInput(theme, l),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedPadding(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeInOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(l),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(
                    '${l.transferVerb} ${amountCtl.formatted} ${getCurrencySymbol(selectedAccount?.currency)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.015),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelector(
    ThemeData theme,
    AppLocalizations l,
    String label,
    List<Account> accounts,
    Account? selected,
    bool expanded,
    Function(Account) onSelected,
    VoidCallback onToggle,
  ) {
    if (accounts.isEmpty) {
      return CustomCard(
        label: l.noAccounts,
        labelStyle: theme.textTheme.titleLarge,
      );
    }
    return TransferAccountDropdown(
      accounts: accounts,
      label: label,
      selectedAccount: selected,
      isExpanded: expanded,
      onAccountSelected: onSelected,
      onToggle: onToggle,
    );
  }

  Widget _buildAmountInput(ThemeData theme, AppLocalizations l) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: amountCtl.focusEnd,
      child: CustomCard(
        label: l.amount,
        labelStyle: theme.textTheme.titleLarge,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AmountNumber(
              theme: theme,
              currency: selectedAccount?.currency ?? 'KZT',
              controller: amountCtl.text,
              focusNode: amountCtl.focus,
              onChanged: (value) =>
                  amountCtl.update(value, () => setState(() {})),
            ),
          ],
        ),
      ),
    );
  }
}
