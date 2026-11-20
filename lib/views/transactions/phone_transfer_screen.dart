import 'dart:async';
import 'package:tarlan_bank/views/shared/amount_input.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../../controllers/accounts_controller.dart';
import '../shared/animated_dropdown.dart';

class PhoneTransferController extends GetxController {
  final AccountsController accountsController = Get.find<AccountsController>();

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  final Rx<AccountModel?> selectedAccount = Rx<AccountModel?>(null);
  final RxString phoneNumber = ''.obs;
  final RxString formattedPhoneNumber = ''.obs;
  final RxString amount = ''.obs;
  String previousNumber = '';
  Transaction? transaction;
  final RxString formattedAmount = ''.obs;
  final RxBool isAccountDropdownExpanded = false.obs;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();

  final int _previousPhoneValue = 0;

  @override
  void onInit() {
    super.onInit();
    amountController.text = '0';
    updateAmount('0');
    _initializeSelectedAccount();
    transaction = Get.arguments;
    if (transaction != null) {
      updatePhoneNumber(transaction?.toUserPhone ?? '');
      print(transaction?.amount.toString());
      updateAmount(transaction?.amount.toString() ?? '');
      // phoneNumber.value = transaction?.toUserPhone ?? '';
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
    accountsController.fetchAccounts().then(
          (_) => _initializeSelectedAccount(),
        );
  }

  void updatePhoneNumber(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    String formatted = '';
    if (digits.isNotEmpty) {
      if (digits.length <= 3) {
        formatted = '($digits';
      } else if (digits.length <= 6) {
        formatted = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
      } else if (digits.length <= 8) {
        formatted =
            '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
      } else {
        formatted =
            '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 8)}-${digits.substring(8)}';
      }
    }

    phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    if (digits.length == 10) {
      accountsController.lookupAccount(phoneNumber: digits);
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
    phoneController.dispose();
    amountController.dispose();
    amountFocusNode.dispose();
    accountsController.recipientAccount.value = null;
    super.onClose();
  }
}

class PhoneTransferScreen extends StatelessWidget {
  final PhoneTransferController controller = Get.put(PhoneTransferController());

  PhoneTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildHeader(context, 'Мобильный перевод'),
              SizedBox(height: size.height * 0.02),
              Expanded(
                child: RefreshIndicator(
                  edgeOffset: MediaQuery.of(context).padding.top,
                  onRefresh: () async {
                    try {
                      await Future.delayed(const Duration(milliseconds: 500));
                    } on TimeoutException {
                      print('Refresh operation timed out');
                    } catch (e) {
                      print('Error during refresh: $e');
                    }
                    return Future.value();
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCardSelector(theme),
                        SizedBox(height: size.height * 0.02),
                        _buildPhoneInput(theme),
                        SizedBox(height: size.height * 0.02),
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
                        controller.amount.value.replaceAll(',', '.'),
                      );
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.selectedAccount.value == null) {
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            fromTop: true,
                            endPositionOffset: 1,
                            title: 'Ошибка',
                            message: 'Пожалуйста, выберите карту',
                          );
                        }
                        return;
                      }
                      String phoneNumber = controller.phoneController.text
                          .replaceAll(RegExp(r'\D'), '');
                      if (phoneNumber.isEmpty) {
                        showAppSnackBar(context,
                            fromTop: true,
                            endPositionOffset: 1,
                            title: 'Ошибка',
                            message: 'Пожалуйста, введите номер телефона');
                        return;
                      }
                      if (controller.amount.value.isEmpty ||
                          double.tryParse(controller.amount.value) == 0) {
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            fromTop: true,
                            endPositionOffset: 1,
                            title: 'Ошибка',
                            message: 'Пожалуйста, введите сумму',
                          );
                        }
                        return;
                      }
                      if (controller
                              .accountsController.recipientAccount.value ==
                          null) {
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            fromTop: true,
                            endPositionOffset: 1,
                            title: 'Ошибка',
                            message: 'Получатель не найден',
                          );
                        }
                        return;
                      }
                      final transaction =
                          await controller.accountsController.createTransaction(
                        controller.selectedAccount.value!.accountNumber,
                        controller.accountsController.recipientAccount.value!
                            .accountNumber,
                        amount,
                        controller.selectedAccount.value!.currency,
                        'phone_transfer',
                      );
                      if (transaction != null &&
                          (transaction.status == 'pending' ||
                              transaction.status == 'completed')) {
                        Navigator.of(Get.context!).pop();
                        Get.toNamed('/transferHistory');
                        Get.toNamed('/transferDetails', arguments: transaction);
                        if (context.mounted) {
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
                        if (context.mounted) {
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
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: size.height * 0.015),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildPhoneInput(ThemeData theme) {
    return CustomCard(
      label: 'Введите номер телефона',
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
                  controller: controller.phoneController,
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
                  onChanged: controller.updatePhoneNumber,
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
                onPressed: () async {
                  final permission = await Permission.contacts.request();
                  if (permission.isGranted) {
                    Contact? contact =
                        await controller._contactPicker.selectContact();
                    if (contact != null &&
                        contact.phoneNumbers != null &&
                        contact.phoneNumbers!.isNotEmpty) {
                      String phoneNumber = contact.phoneNumbers!
                          .toString()
                          .replaceAll(RegExp(r'\D'), '')
                          .substring(1);

                      controller.phoneController.text = phoneNumber;
                      controller.updatePhoneNumber(phoneNumber);
                    }
                  }
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Obx(
              () {
                return Text(
                  controller.accountsController.recipientAccount.value
                          ?.fullName ??
                      'Получатель не найден',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(ThemeData theme) {
    return Obx(
      () => GestureDetector(
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
      ),
    );
  }
}
