import 'package:tarlan_bank/views/shared/amount_input.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../../controllers/accounts_controller.dart';
import '../shared/animated_dropdown.dart';

class CardTransferController extends GetxController {
  final AccountsController accountsController = Get.find<AccountsController>();

  final Rx<AccountModel?> selectedAccount = Rx<AccountModel?>(null);
  final RxString accountNumber = ''.obs;
  final RxString formattedAccountNumber = ''.obs;
  final RxString amount = ''.obs;
  String previousNumber = '';
  Transaction? transaction;
  final RxString formattedAmount = ''.obs;
  final RxBool isAccountDropdownExpanded = false.obs;

  final TextEditingController accountController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _initializeSelectedAccount();
    amountController.text = '0';
    updateAmount('0');
    transaction = Get.arguments;
    if (transaction != null) {
      updateAccountNumber(transaction?.toAccount ?? '');
      updateAmount(transaction?.amount.toString() ?? '');
    }
  }

  void _initializeSelectedAccount() {
    if (accountsController.accounts.isNotEmpty) {
      final cards = accountsController.accounts
          .where((account) => account.accountType == 'card')
          .toList()
        ..sort((a, b) => b.balance.compareTo(a.balance));

      selectedAccount.value = cards.isNotEmpty ? cards.first : null;
    }
  }

  void refreshCards() {
    accountsController
        .fetchAccounts()
        .then((_) => _initializeSelectedAccount());
  }

  void updateAccountNumber(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    String formatted = '';

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    accountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    if (formatted.replaceAll(' ', '').length == 16) {
      accountsController.lookupAccount(
          accountNumber: formatted.replaceAll(' ', ''));
    } else {
      accountsController.recipientAccount.value = null;
    }
  }

  void updateAmount(String value) {
    const int maxTransferAmount = 2000000;
    String normalizedValue = value.replaceAll('.', ',');

    List<String> parts = normalizedValue.split(',');
    String integerPart = parts[0].replaceAll(RegExp(r'\D'), '');
    String decimalPart =
        parts.length > 1 ? parts[1].replaceAll(RegExp(r'\D'), '') : '';

    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    if (integerPart.isEmpty) {
      amount.value = '';
      formattedAmount.value = '0';
      amountController.value = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
      return;
    }

    int number = int.tryParse(integerPart) ?? 0;

    if (number > maxTransferAmount) {
      print(number);
      number = int.parse(previousNumber.split(',')[0]);
      String formatted = _formatAmount(number);

      if (normalizedValue.contains(',')) {
        formatted += ',$decimalPart';
      }

      _updateControllerValue(formatted);
      return;
    }

    String formatted = _formatAmount(number);
    if (normalizedValue.contains(',')) {
      formatted += ',$decimalPart';
    }

    amount.value =
        number.toString() + (decimalPart.isNotEmpty ? ',$decimalPart' : '');
    formattedAmount.value = formatted;
    previousNumber = amount.value;

    _updateControllerValue(formatted);
  }

  String _formatAmount(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  void _updateControllerValue(String formatted) {
    final oldCursor = amountController.selection.start;
    final oldTextLength = amountController.text.length;
    final distanceFromEnd = oldTextLength - oldCursor;

    amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length - distanceFromEnd,
      ),
    );
  }

  @override
  void onClose() {
    accountController.dispose();
    amountController.dispose();
    amountFocusNode.dispose();
    accountsController.recipientAccount.value = null;
    super.onClose();
  }
}

class CardTransferScreen extends StatelessWidget {
  final CardTransferController controller = Get.put(CardTransferController());

  CardTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(children: [
                  buildHeader(context, 'По номеру счета'),
                  SizedBox(
                    height: size.height * 0.02,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildCardSelector(theme),
                          SizedBox(height: size.height * 0.02),
                          _buildAccountInput(theme),
                          SizedBox(height: size.height * 0.02),
                          _buildAmountInput(theme),
                        ],
                      ),
                    ),
                  ),
                  Obx(() {
                    double amount = controller.amount.value.isEmpty
                        ? 0
                        : double.parse(
                            controller.amount.value.replaceAll(',', '.'));
                    return AnimatedPadding(
                        duration: const Duration(milliseconds: 50),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.selectedAccount.value == null) {
                              if (context.mounted == true) {
                                showAppSnackBar(
                                  context,
                                  endPositionOffset: 1,
                                  title: 'Ошибка',
                                  message: 'Пожалуйста, выберите карту',
                                );
                              }
                              return;
                            }
                            String accountNumber = controller
                                .accountController.text
                                .replaceAll(' ', '');
                            if (accountNumber.length != 16) {
                              if (context.mounted == true) {
                                showAppSnackBar(
                                  context,
                                  endPositionOffset: 1,
                                  title: 'Ошибка',
                                  message:
                                      'Пожалуйста, введите корректный номер счета',
                                );
                              }
                              return;
                            }

                            if (controller.amount.value.isEmpty) {
                              if (context.mounted == true) {
                                showAppSnackBar(
                                  context,
                                  endPositionOffset: 1,
                                  title: 'Ошибка',
                                  message: 'Пожалуйста, введите сумму',
                                );
                              }
                              return;
                            }

                            if (controller.accountsController.recipientAccount
                                    .value ==
                                null) {
                              if (context.mounted == true) {
                                showAppSnackBar(
                                  context,
                                  endPositionOffset: 1,
                                  title: 'Ошибка',
                                  message: 'Получатель не найден',
                                );
                              }
                              return;
                            }

                            final transaction = await controller
                                .accountsController
                                .createTransaction(
                                    controller
                                        .selectedAccount.value!.accountNumber,
                                    controller.accountsController
                                        .recipientAccount.value!.accountNumber,
                                    amount,
                                    controller.selectedAccount.value!.currency,
                                    'card_transfer');

                            if (transaction != null &&
                                transaction.status == 'completed') {
                              Navigator.of(Get.context!).pop();
                              Get.toNamed('/transferHistory');
                              Get.toNamed('/transferDetails',
                                  arguments: transaction);
                              if (context.mounted == true) {
                                showAppSnackBar(
                                  context,
                                  fromTop: true,
                                  endPositionOffset: 1,
                                  title: 'Успех',
                                  message: 'Перевод успешно выполнен',
                                );
                              }
                              controller.refreshCards();
                            } else {
                              if (context.mounted == true) {
                                showAppSnackBar(
                                  context,
                                  fromTop: true,
                                  endPositionOffset: 1,
                                  title: 'Ошибка',
                                  message: 'Перевод не выполнен',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          child: Text(
                              'Перевести ${controller.formattedAmount.value} ${getCurrencySymbol(controller.selectedAccount.value?.currency)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Roboto',
                              )),
                        ));
                  }),
                  SizedBox(
                    height: size.height * 0.015,
                  ),
                ]))));
  }

  Widget buildCardSelector(ThemeData theme) {
    return Obx(() {
      if (controller.accountsController.accounts.isEmpty) {
        return CustomCard(
          label: 'У вас нет доступных счетов',
          labelStyle: theme.textTheme.titleLarge,
        );
      }
      return AnimatedCardDropdown(
        accounts: controller.accountsController.accounts,
        label: 'Откуда',
        selectedAccount: controller.selectedAccount.value,
        isExpanded: controller.isAccountDropdownExpanded.value,
        onAccountSelected: (account) {
          controller.selectedAccount.value = account;
          controller.isAccountDropdownExpanded.value = false;
        },
        onToggle: () => controller.isAccountDropdownExpanded.toggle(),
      );
    });
  }

  Widget _buildAccountInput(ThemeData theme) {
    return CustomCard(
      label: 'Номер счета получателя',
      labelStyle: theme.textTheme.titleLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentGeometry.centerLeft,
            child: TextField(
              controller: controller.accountController,
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
              onChanged: (raw) {
                controller.updateAccountNumber(raw);
              },
            ),
          ),
          if (controller.accountController.text.replaceAll(' ', '').length ==
              16)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Text(
                    controller.accountsController.recipientAccount.value
                            ?.fullName ??
                        'Получатель не найден',
                    style: theme.textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(ThemeData theme) {
    return Obx(() => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            controller.amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.amountController.text.length),
            );
            controller.amountFocusNode.requestFocus();
          },
          child: CustomCard(
            label: 'Сумма',
            labelStyle: theme.textTheme.titleLarge,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                AmountNumber(
                  theme: theme,
                  currency: controller.selectedAccount.value?.currency ?? 'KZT',
                  controller: controller.amountController,
                  focusNode: controller.amountFocusNode,
                  onChanged: controller.updateAmount,
                ),
              ],
            ),
          ),
        ));
  }
}
