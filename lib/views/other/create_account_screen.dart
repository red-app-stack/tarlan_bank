import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/locale/product_labels.dart';
import 'package:tarlan_bank/core/router/app_navigation.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/data/product_type.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/custom_input_field.dart';

/// Account creation, migrated off the disposed GetX binding to Riverpod.
/// The old `Bind.lazyPut` controller was deleted on route pop and never
/// recreated — reopening the screen hit `Get.find` on a null controller.
/// Local form state + a provider-backed repository cannot be disposed away.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key, this.accountType = 'card'});

  /// Product requested by home/menu tiles: card | deposit | credit | transfer.
  final String accountType;

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _monthlyIncome = TextEditingController();
  final _additionalIncome = TextEditingController();
  final _documentNumber = TextEditingController();
  final _documentExpiry = TextEditingController();

  final FocusNode _monthlyIncomeFocus = FocusNode();
  final FocusNode _additionalIncomeFocus = FocusNode();
  final FocusNode _documentNumberFocus = FocusNode();
  final FocusNode _documentExpiryFocus = FocusNode();

  late String _currency = 'KZT';
  late String _selectedDocument = documentTypeKeys.first;
  bool _isLoading = false;
  bool _isNotUsCitizen = false;

  @override
  void initState() {
    super.initState();
    _documentExpiry.text = _formatDate(
      DateTime.now().add(const Duration(days: 182)),
    );
    _documentNumber.text = _generateDocumentNumber();
    _prefillProfile(ref.read(userProfileProvider).value);
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _phone,
      _birthDate,
      _monthlyIncome,
      _additionalIncome,
      _documentNumber,
      _documentExpiry,
    ]) {
      c.dispose();
    }
    for (final f in [
      _monthlyIncomeFocus,
      _additionalIncomeFocus,
      _documentNumberFocus,
      _documentExpiryFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  void _prefillProfile(Map<String, dynamic>? profile) {
    if (profile == null) return;
    if (_fullName.text.isEmpty) _fullName.text = profile['fullName'] ?? '';
    if (_phone.text.isEmpty) {
      final phone = profile['phoneNumber']?.toString() ?? '';
      _phone.text = phone.isEmpty ? '' : '+7 $phone';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  String _generateDocumentNumber() {
    final random = DateTime.now().microsecondsSinceEpoch % 1000000000;
    return random.toString().padLeft(9, '0').substring(0, 9);
  }

  double _interestRate(String currency) => currency == 'KZT' ? 18.5 : 1.0;

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 182)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7300)),
    );
    if (picked != null && mounted) {
      setState(() => _documentExpiry.text = _formatDate(picked));
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      _snack(
        false,
        l.signInRequired,
        product: productLabel(l, widget.accountType),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final type = accountTypeFromProduct(widget.accountType);
      final now = DateTime.now();
      final double income =
          double.tryParse(_monthlyIncome.text.replaceAll(',', '.')) ?? 0;
      await ref
          .read(accountsRepositoryProvider)
          .createAccount(
            ownerId: user.uid,
            type: type,
            currency: _currency,
            depositTerms: type == AccountType.deposit
                ? DepositTerms(
                    annualRate: 0.14,
                    termMonths: 12,
                    maturityAt: now.add(const Duration(days: 365)),
                  )
                : null,
            creditTerms: type == AccountType.credit
                ? CreditTerms(
                    creditLimit: income > 0 ? income * 6 : 1000000,
                    annualRate: 0.185,
                    termMonths: 24,
                  )
                : null,
          );
      ref.invalidate(accountsProvider);
      _snack(true, null, product: productLabel(l, widget.accountType));
      if (mounted) {
        await navigateToMainTab(context, '/accounts');
      }
    } on AppFailure catch (e) {
      _snack(false, e.message, product: productLabel(l, widget.accountType));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(bool success, String? details, {required String product}) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    showAppSnackBar(
      context,
      endPositionOffset: 1,
      title: success ? l.success : l.error,
      message: success
          ? l.productOpened(product)
          : details ?? l.failedOpen(product),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prefill once the Firestore profile stream produces data.
    ref.listen(userProfileProvider, (_, next) => _prefillProfile(next.value));
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                spacing: 16,
                children: [
                  const SizedBox(),
                  buildHeader(
                    context,
                    l.openProduct(productLabel(l, widget.accountType)),
                  ),
                  _buildCurrencySection(theme, l),
                  _buildPersonalInfoSection(theme, l),
                  _buildFinancialInfoSection(theme, l),
                  _buildDocumentSection(theme, l),
                  _buildSubmitButton(theme, l),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySection(ThemeData theme, AppLocalizations l) {
    final currencies = ['KZT', 'USD', 'EUR'];
    return CustomCard(
      label: l.currency,
      labelStyle: theme.textTheme.titleLarge,
      child: LayoutBuilder(
        builder: (context, constraints) => IntrinsicHeight(
          child: Row(
            children: List.generate(currencies.length * 2 - 1, (index) {
              if (index.isOdd) return const SizedBox(width: 8);
              final currency = currencies[index ~/ 2];
              final selected = _currency == currency;
              return Flexible(
                flex: selected ? 3 : 2,
                child: ChoiceChip(
                  labelPadding: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(currency),
                      if (widget.accountType == 'deposit' && selected)
                        Text(
                          l.interestRate(_interestRate(currency).toString()),
                        ),
                    ],
                  ),
                  selected: selected,
                  onSelected: (value) {
                    if (value) setState(() => _currency = currency);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(ThemeData theme, AppLocalizations l) {
    return CustomCard(
      label: l.personalInfo,
      labelStyle: theme.textTheme.titleLarge,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInputField(
            controller: _fullName,
            label: l.fullName,
            prefixIcon: Icons.person_outline,
            enabled: false,
            filled: true,
          ),
          CustomInputField(
            controller: _phone,
            label: l.phone,
            prefixIcon: Icons.phone_outlined,
            enabled: false,
            filled: true,
          ),
          CustomInputField(
            controller: _birthDate,
            label: l.birthDate,
            prefixIcon: Icons.calendar_today_outlined,
            enabled: false,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoSection(ThemeData theme, AppLocalizations l) {
    if (widget.accountType != 'credit' && widget.accountType != 'transfer') {
      return const SizedBox.shrink();
    }
    return CustomCard(
      label: l.financialInfo,
      labelStyle: theme.textTheme.titleLarge,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInputField(
            controller: _monthlyIncome,
            focusNode: _monthlyIncomeFocus,
            label: l.monthlyIncome,
            prefixIcon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            suffix: _currency,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_additionalIncomeFocus),
          ),
          CustomInputField(
            controller: _additionalIncome,
            focusNode: _additionalIncomeFocus,
            label: l.additionalIncome,
            prefixIcon: Icons.add_card_outlined,
            keyboardType: TextInputType.number,
            suffix: _currency,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(ThemeData theme, AppLocalizations l) {
    return CustomCard(
      label: l.documents,
      labelStyle: theme.textTheme.titleLarge,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedDocument,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.docType,
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            menuMaxHeight: MediaQuery.of(context).size.height * 0.3,
            items: documentTypeKeys
                .map(
                  (key) => DropdownMenuItem(
                    value: key,
                    child: Text(documentTypeLabel(l, key)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(
              () => _selectedDocument = value ?? documentTypeKeys.first,
            ),
          ),
          CustomInputField(
            controller: _documentNumber,
            label: l.docNumber,
            prefixIcon: Icons.numbers_outlined,
            enabled: false,
            filled: true,
          ),
          CustomInputField(
            controller: _documentExpiry,
            label: l.docExpiry,
            prefixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _selectExpiryDate,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l) {
    return SimpleCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => setState(() => _isNotUsCitizen = !_isNotUsCitizen),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IgnorePointer(
                    child: Checkbox(
                      value: _isNotUsCitizen,
                      onChanged: (value) =>
                          setState(() => _isNotUsCitizen = value ?? false),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.notUsCitizen,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _isNotUsCitizen
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(l.openProduct(productLabel(l, widget.accountType))),
            ),
          ),
        ],
      ),
    );
  }
}
