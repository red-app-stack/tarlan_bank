import 'dart:async';
import 'package:tarlan_bank/views/shared/amount_input.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/accounts_controller.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../shared/animated_dropdown.dart';
import '../shared/formatters.dart';

class ConvertController extends GetxController {
  final AccountsController accountsController = Get.find<AccountsController>();

  final Rx<AccountModel?> selectedAccount = Rx<AccountModel?>(null);
  final RxString amount = ''.obs;
  String previousNumber = '';
  Transaction? transaction;
  final RxString formattedAmount = ''.obs;
  final RxBool isAccountDropdownExpanded = false.obs;
  final Rx<AccountModel?> selectedDestinationAccount = Rx<AccountModel?>(null);
  final RxBool isDestinationDropdownExpanded = false.obs;

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
      print(transaction?.amount.toString());
      updateAmount(transaction?.amount.toString() ?? '');
      // phoneNumber.value = transaction?.toUserPhone ?? '';
    }
  }

  void _initializeSelectedAccount() {
    final cards = accountsController.accounts
        .where((account) => account.accountType == 'card')
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    if (accountsController.accounts.length > 1) {
      // final cards = accountsController.accounts.where((account) => account.accountType == 'card').toList()..sort((a, b) => b.balance.compareTo(a.balance));

      selectedAccount.value = cards.isNotEmpty ? cards.first : null;
      selectedDestinationAccount.value = cards.length > 1 ? cards[1] : null;
    } else if (accountsController.accounts.length == 1) {
      selectedAccount.value = cards.first;
    }
  }

  void refreshCards() {
    accountsController
        .fetchAccounts()
        .then((_) => _initializeSelectedAccount());
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
    amountController.dispose();
    amountFocusNode.dispose();
    accountsController.recipientAccount.value = null;
    super.onClose();
  }
}

class ConvertScreen extends StatelessWidget {
  final ConvertController controller = Get.put(ConvertController());

  ConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(children: [
                  buildHeader(context, 'Конвертация'),
                  SizedBox(
                    height: size.height * 0.02,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      edgeOffset: MediaQuery.of(context).padding.top,
                      onRefresh: () async {
                        try {
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        } on TimeoutException {
                          print('Refresh operation timed out');
                        } catch (e) {
                          print('Error during refresh: $e');
                        }
                        return Future.value();
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 24,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildCardSelector(theme),
                            buildDestinationCardSelector(theme),
                            _buildAmountInput(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    double amount = controller.amount.value.isEmpty
                        ? 0
                        : double.parse(
                            controller.amount.value.replaceAll(',', '.'));
                    return ElevatedButton(
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

                        if (controller.selectedDestinationAccount.value ==
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

                        final transaction = await controller.accountsController
                            .createTransaction(
                                controller.selectedAccount.value!.accountNumber,
                                controller.selectedDestinationAccount.value!
                                    .accountNumber,
                                amount,
                                controller.selectedAccount.value!.currency,
                                'internal_transfer');

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
                    );
                  }),
                  SizedBox(
                    height: size.height * 0.015,
                  ),
                ]))));
  }

  Widget buildCardSelector(ThemeData theme) {
    return Obx(() {
      if (controller.accountsController.accounts.isEmpty) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'У вас нет доступных счетов',
              style: theme.textTheme.titleMedium,
            ),
          ),
        );
      }
      final availableAccounts = controller.accountsController.accounts
          .where((account) =>
              account != controller.selectedDestinationAccount.value)
          .toList();
      return AnimatedCardDropdown(
        accounts: availableAccounts,
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

  Widget buildDestinationCardSelector(ThemeData theme) {
    return Obx(() {
      if (controller.accountsController.accounts.isEmpty ||
          controller.accountsController.accounts.length < 2) {
        return CustomCard(
          label: 'У вас нет доступных счетов',
          labelStyle: theme.textTheme.titleLarge,
        );
      }

      final availableAccounts = controller.accountsController.accounts
          .where((account) => account != controller.selectedAccount.value)
          .toList();

      return AnimatedCardDropdown(
        accounts: availableAccounts,
        label: 'Куда',
        selectedAccount: controller.selectedDestinationAccount.value,
        isExpanded: controller.isDestinationDropdownExpanded.value,
        onAccountSelected: (account) {
          controller.selectedDestinationAccount.value = account;
          controller.isDestinationDropdownExpanded.value = false;
        },
        onToggle: () => controller.isDestinationDropdownExpanded.toggle(),
      );
    });
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
