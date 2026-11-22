import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/transactions/widgets/transfer_error_message.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';
import 'package:tarlan_bank/features/transactions/providers/transactions_providers.dart';
import 'package:tarlan_bank/features/transactions/providers/transfer_ui_providers.dart';
import 'package:tarlan_bank/features/transactions/widgets/recipient_identity.dart';
import 'package:tarlan_bank/features/transactions/widgets/account_dropdown.dart';
import 'package:tarlan_bank/features/transactions/widgets/transfer_header.dart';
import 'package:tarlan_bank/features/transactions/widgets/transfer_amount_controller.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/amount_input.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';

class CardTransferScreen extends ConsumerStatefulWidget {
  const CardTransferScreen({super.key, this.transaction});

  /// Optional prefill. go_router builds this screen with no arguments; when
  /// null the screen simply starts empty (never crashes).
  final BankTransaction? transaction;

  @override
  ConsumerState<CardTransferScreen> createState() => _CardTransferScreenState();
}

class _CardTransferScreenState extends ConsumerState<CardTransferScreen> {
  final TransferAmountController amountCtl = TransferAmountController();
  final TextEditingController accountController = TextEditingController();
  Timer? _lookupTimer;

  Account? selectedAccount;
  bool isAccountDropdownExpanded = false;
  bool _initialized = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    amountCtl.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInitialTransaction();
      ref.read(transferLookupProvider.notifier).clear();
    });
  }

  void _applyInitialTransaction() {
    final initial = widget.transaction ?? ref.read(selectedTransactionProvider);
    ref.read(selectedTransactionProvider.notifier).clear();
    if (initial == null) return;
    if (initial.amount > 0) {
      amountCtl.update(initial.amount.toString(), () {});
    }
    final target = initial.toAccountId;
    if (target != null && target.isNotEmpty) {
      accountController.text = _formatAccount(target);
    }
  }

  @override
  void dispose() {
    _lookupTimer?.cancel();
    amountCtl.dispose();
    accountController.dispose();
    super.dispose();
  }

  String _formatAccount(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void _onAccountChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final formatted = _formatAccount(digits);
    accountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _lookupTimer?.cancel();
    if (digits.length == 16) {
      ref.read(transferLookupProvider.notifier).begin();
      _lookupTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _lookupRecipient(digits);
      });
    } else {
      ref.read(transferLookupProvider.notifier).clear();
    }
    setState(() {});
  }

  Future<void> _lookupRecipient(String number) async {
    try {
      await ref
          .read(transferLookupProvider.notifier)
          .lookup(accountNumber: number, scheduled: true);
    } on Object {
      if (mounted) ref.read(transferLookupProvider.notifier).clear();
    }
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

  void _syncSelection(List<Account> accounts) {
    final source = _sourceAccounts(accounts);
    if (source.isEmpty) {
      if (selectedAccount != null) setState(() => selectedAccount = null);
      return;
    }
    if (selectedAccount == null ||
        !source.any((a) => a.number == selectedAccount!.number)) {
      setState(() => selectedAccount = source.first);
    }
  }

  Future<void> _submit(AppLocalizations l) async {
    if (_submitting) return;
    if (selectedAccount == null) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.errorSelectCard,
      );
      return;
    }
    final digits = accountController.text.replaceAll(' ', '');
    if (digits.length != 16) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.errorEnterAccount,
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
    final recipient = ref.read(transferLookupProvider).account;
    if (recipient == null) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.recipientNotFound,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final tx = await ref
          .read(transactionsRepositoryProvider)
          .createTransaction(
            fromAccountId: selectedAccount!.number,
            toAccountId: recipient.number,
            amount: amountCtl.parsed,
            currency: selectedAccount!.currency,
            type: TransactionType.cardTransfer,
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
    } on AppFailure catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          fromTop: true,
          endPositionOffset: 1,
          title: l.error,
          message: transferErrorMessage(e, l),
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
    final lookup = ref.watch(transferLookupProvider);
    final visibleAccounts = _sourceAccounts(accounts);

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelection(accounts);
      });
    }

    return Scaffold(
      appBar: buildTransferHeader(context, l.typeCardTransfer),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardSelector(theme, l, visibleAccounts),
                      SizedBox(height: size.height * 0.02),
                      _buildAccountInput(theme, l, lookup),
                      SizedBox(height: size.height * 0.02),
                      _buildAmountInput(theme, l),
                    ],
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

  Widget _buildCardSelector(
    ThemeData theme,
    AppLocalizations l,
    List<Account> accounts,
  ) {
    if (accounts.isEmpty) {
      return CustomCard(
        label: l.noAccounts,
        labelStyle: theme.textTheme.titleLarge,
      );
    }
    return TransferAccountDropdown(
      accounts: accounts,
      label: l.from,
      selectedAccount: selectedAccount,
      isExpanded: isAccountDropdownExpanded,
      onAccountSelected: (account) => setState(() {
        selectedAccount = account;
        isAccountDropdownExpanded = false;
      }),
      onToggle: () => setState(
        () => isAccountDropdownExpanded = !isAccountDropdownExpanded,
      ),
    );
  }

  Widget _buildAccountInput(
    ThemeData theme,
    AppLocalizations l,
    TransferLookupState lookup,
  ) {
    return CustomCard(
      label: l.recipientAccountNumber,
      labelStyle: theme.textTheme.titleLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: accountController,
              keyboardType: TextInputType.number,
              maxLength: 19,
              style: theme.textTheme.titleLarge,
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: '0000 0000 0000 0000',
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                contentPadding: const EdgeInsets.only(left: 16, right: 16),
              ),
              onChanged: _onAccountChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RecipientIdentity(
              state: lookup,
              show: accountController.text.replaceAll(' ', '').length == 16,
            ),
          ),
        ],
      ),
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
