import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
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

class PhoneTransferScreen extends ConsumerStatefulWidget {
  const PhoneTransferScreen({super.key, this.transaction});

  /// Optional prefill; null is handled as an empty form.
  final BankTransaction? transaction;

  @override
  ConsumerState<PhoneTransferScreen> createState() =>
      _PhoneTransferScreenState();
}

class _PhoneTransferScreenState extends ConsumerState<PhoneTransferScreen> {
  final TransferAmountController amountCtl = TransferAmountController();
  final TextEditingController phoneController = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
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
    // The new ledger model stores account ids, not phone numbers; the
    // account-id prefill is still enough to show a valid recipient path.
  }

  @override
  void dispose() {
    _lookupTimer?.cancel();
    amountCtl.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    phoneController.value = TextEditingValue(
      text: formatPhone(digits),
      selection: TextSelection.collapsed(offset: formatPhone(digits).length),
    );
    _lookupTimer?.cancel();
    if (digits.length == 10) {
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
          .lookup(phoneNumber: number);
    } on Object {
      if (mounted) ref.read(transferLookupProvider.notifier).clear();
    }
  }

  Future<void> _pickContact() async {
    final permission = await Permission.contacts.request();
    if (!permission.isGranted) return;
    final Contact? contact = await _contactPicker.selectContact();
    final numbers = contact?.phoneNumbers;
    if (numbers == null || numbers.isEmpty) return;
    var digits = numbers.toString().replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);
    _onPhoneChanged(digits);
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
        fromTop: true,
        endPositionOffset: 1,
        title: l.error,
        message: l.errorSelectCard,
      );
      return;
    }
    if (phoneController.text.replaceAll(RegExp(r'\D'), '').isEmpty) {
      showAppSnackBar(
        context,
        fromTop: true,
        endPositionOffset: 1,
        title: l.error,
        message: l.errorEnterPhone,
      );
      return;
    }
    if (amountCtl.isEmpty) {
      showAppSnackBar(
        context,
        fromTop: true,
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
        fromTop: true,
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
            type: TransactionType.phoneTransfer,
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
    final lookup = ref.watch(transferLookupProvider);
    final visibleAccounts = _sourceAccounts(accounts);

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncSelection(accounts);
      });
    }

    return Scaffold(
      appBar: buildTransferHeader(context, l.transferByPhone),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                        _buildCardSelector(theme, l, visibleAccounts),
                        SizedBox(height: size.height * 0.02),
                        _buildPhoneInput(theme, l, lookup),
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

  Widget _buildPhoneInput(
    ThemeData theme,
    AppLocalizations l,
    TransferLookupState lookup,
  ) {
    return CustomCard(
      label: l.enterPhoneNumber,
      labelStyle: theme.textTheme.titleLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text('+7 ', style: theme.textTheme.titleLarge),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.titleLarge,
                  cursorColor: theme.colorScheme.primary,
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: '(000) 000-00-00',
                    hintStyle: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    contentPadding: const EdgeInsets.only(left: 0, right: 16),
                  ),
                  onChanged: _onPhoneChanged,
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/ic_user.svg',
                  width: 36,
                  height: 36,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: _pickContact,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: RecipientIdentity(
              state: lookup,
              show:
                  phoneController.text.replaceAll(RegExp(r'\D'), '').length ==
                  10,
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
