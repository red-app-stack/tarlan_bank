import 'dart:convert';
import 'dart:math';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/views/shared/amount_input.dart';
import 'package:tarlan_bank/views/shared/app_snack_bar.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/accounts_controller.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../shared/animated_dropdown.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRTtransferController extends GetxController {
  final AccountsController accountsController = Get.find<AccountsController>();
  final UserRepository userRepo = Get.find<UserRepository>();
  MobileScannerController? scannerController;
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final Rx<Transaction?> transaction = Rx<Transaction?>(null);

  final RxBool isScanning = true.obs;
  final Rx<AccountModel?> selectedAccount = Rx<AccountModel?>(null);
  final RxBool isAccountDropdownExpanded = false.obs;

  final Rx<Map<String, dynamic>?> scannedData = Rx<Map<String, dynamic>?>(null);
  final RxBool showPaymentView = false.obs;

  final RxString amount = ''.obs;
  final RxString formattedAmount = ''.obs;
  String previousNumber = '';
  final TextEditingController amountController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();

  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  void toggleMode(bool scanning) {
    isScanning.value = scanning;
  }

  void focusNextInput() {
    if (amountFocusNode.hasFocus) {
      messageFocusNode.requestFocus();
    }
  }

  String generateQRData() {
    final user = userRepo.currentUser;
    final selectedAcc = selectedAccount.value;

    if (user == null || selectedAcc == null) return '';

    Map<String, dynamic> qrData = {
      'fullName': user.fullName,
      'accountNumber': selectedAcc.accountNumber,
      'currency': selectedAcc.currency,
      'amount': amount.value,
      'message': messageController.text,
    };

    return jsonEncode(qrData);
  }

  void processScannedQR(String? rawData) {
    if (rawData == null) return;

    try {
      print('Scanned data: $rawData');
      final data = jsonDecode(rawData);
      if (data['accountNumber'] != null && data['currency'] != null) {
        scannedData.value = data;
        showPaymentView.value = true;
        if (data['amount'] != null &&
            (data['amount']?.isNotEmpty ?? false) &&
            (int.tryParse(data['amount'] ?? '') ?? 0) > 0) {
          updateAmount(data['amount']);
          amountController.text = data['amount'];
        }
        if (data['message'] != null) {
          messageController.text = data['message'];
        }
      }
    } catch (e) {
      print('Invalid QR format: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();

    _initializeSelectedAccount();
    initializeScannerController();

    amountController.text = '0';
    updateAmount('0');

    _handleArguments();
  }

  void _handleArguments() {
    final args = Get.arguments;

    if (args is Transaction) {
      transaction.value = args;

      final data = {
        'fullName': args.toUserName ?? '',
        'accountNumber': args.toAccount,
        'currency': args.currency,
        'amount': args.amount.toString(),
        'message': args.message,
      };

      if (args.amount > 0) {
        updateAmount(args.amount.toString());
        amountController.text = args.amount.toString();
      }
      print('message ${args.message}');

      if (args.message.isNotEmpty) {
        messageController.text = args.message;
      }

      scannedData.value = data;
      showPaymentView.value = true;
    }
  }

  void initializeScannerController() {
    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void onClose() {
    scannerController?.dispose();
    super.onClose();
  }

  void _initializeSelectedAccount() {
    if (accountsController.accounts.isNotEmpty) {
      selectedAccount.value = accountsController.accounts.first;
    }
  }

  void refreshCards() {
    accountsController.fetchAccounts().then(
          (_) => _initializeSelectedAccount(),
        );
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
}

class QRTransferScreen extends StatelessWidget {
  final QRTtransferController controller = Get.put(QRTtransferController());
  final qrKey = GlobalKey(debugLabel: 'QR');

  QRTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: buildHeader(context, 'Перевод по QR'),
            ),
            const SizedBox(height: 16),
            _buildToggleSwitch(context),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(
                () => controller.isScanning.value
                    ? _buildQrView(context)
                    : _buildCreator(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(BuildContext context) {
    return Obx(
      () => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.inverseSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: controller.isScanning.value
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.toggleMode(true),
                      behavior: HitTestBehavior.opaque,
                      child: _buildToggleOption(
                        context: context,
                        title: "Сканировать",
                        isSelected: controller.isScanning.value,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.toggleMode(false),
                      behavior: HitTestBehavior.opaque,
                      child: _buildToggleOption(
                        context: context,
                        title: "Создать",
                        isSelected: !controller.isScanning.value,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
  }) {
    return AnimatedDefaultTextStyle(
      style: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.outline,
        fontWeight: FontWeight.bold,
      ),
      duration: Duration(milliseconds: 200),
      child: Center(child: Text(title)),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return Obx(
      () => controller.showPaymentView.value
          ? _buildPaymentView(context)
          : _buildScanner(context),
    );
  }

  Widget _buildPaymentView(BuildContext context) {
    final scannedData = controller.scannedData.value!;
    double amount = controller.amount.value.isEmpty
        ? 0.0
        : double.parse(
            controller.amount.value.replaceAll(' ', '').replaceAll(',', '.'),
          );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildCardSelector(context, 'Откуда'),
                  const SizedBox(height: 16),
                  _buildAmountInput(
                    context,
                    readOnly: (amount != 0 && amount != 0.0),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Получатель: ${scannedData['fullName']}'),
                            if (scannedData['message']?.isNotEmpty ?? false)
                              Text('Сообщение: ${scannedData['message']}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            double amount = controller.amount.value.isEmpty
                ? 0.0
                : double.parse(
                    controller.amount.value
                        .replaceAll(' ', '')
                        .replaceAll(',', '.'),
                  );

            final formattedAmount = amount.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]} ',
                );

            return SizedBox(
              width: double.infinity,
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

                  if (controller.amount.value.isEmpty ||
                      controller.amount.value == '0') {
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

                  if (scannedData['accountNumber'] == null) {
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

                  final transaction =
                      await controller.accountsController.createTransaction(
                    controller.selectedAccount.value!.accountNumber,
                    scannedData['accountNumber'],
                    double.parse(controller.amount.value),
                    controller.selectedAccount.value!.currency,
                    'qr_transfer',
                    message: controller.messageController.text,
                  );
                  if (transaction != null &&
                      (transaction.status == 'pending' ||
                          transaction.status == 'completed')) {
                    Navigator.of(Get.context!).pop();
                    Get.toNamed('/transferHistory');
                    Get.toNamed('/transferDetails', arguments: transaction);
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  'Перевести ${formattedAmount.replaceAll('.', ',')} ₸',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Roboto',
                      ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
      ],
    );
  }

  Widget _buildScanner(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(
        Offset.fromDirection(
          -pi / 2,
          MediaQuery.of(context).size.height * 0.15,
        ),
      ),
      width: scanArea,
      height: scanArea,
    );

    return Stack(
      children: [
        MobileScanner(
          scanWindow: scanWindow,
          controller: controller.scannerController!,
          errorBuilder: (context, error) {
            return ScannerErrorWidget(error: error);
          },
          onDetect: (capture) {
            final String? code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) {
              controller.processScannedQR(code);
            }
          },
        ),
        controller.scannerController == null
            ? SizedBox()
            : ValueListenableBuilder(
                valueListenable: controller.scannerController!,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: ScannerOverlay(scanWindow: scanWindow),
                  );
                },
              ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          final BarcodeCapture? barcodes = await controller
                              .scannerController!
                              .analyzeImage(image.path);
                          if (barcodes != null &&
                              barcodes.barcodes.isNotEmpty) {
                            final String? code =
                                barcodes.barcodes.first.rawValue;
                            if (code != null) {
                              controller.processScannedQR(code);
                            }
                          }
                        }
                      },
                      child: SvgPicture.asset('assets/icons/ic_gallery.svg'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await controller.scannerController?.toggleTorch();
                      },
                      child: SvgPicture.asset('assets/icons/ic_flash.svg'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreator(BuildContext context) {
    // final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          buildCardSelector(context, 'Куда'),
          const SizedBox(height: 16),
          _buildAmountInput(context, readOnly: false),
          const SizedBox(height: 16),
          _buildMessageInput(context),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SvgPicture.asset(
                    'assets/icons/attention.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.outline,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Если не казать сумму перевода, она может быть указана отправителем при сканировании вашего QR',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PrettyQrView.data(
                      data: controller.generateQRData(),
                      decoration: const PrettyQrDecoration(
                        image: PrettyQrDecorationImage(
                          image: AssetImage('assets/images/app_icon.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Text(
              'Создать QR код',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                  ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context, {required readOnly}) {
    ThemeData theme = Theme.of(context);

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
                enabled: !readOnly,
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

  Widget _buildMessageInput(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        controller.messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.messageController.text.length),
        );
        controller.messageFocusNode.requestFocus();
      },
      child: CustomCard(
        child: TextField(
          focusNode: controller.messageFocusNode,
          controller: controller.messageController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: theme.textTheme.titleLarge,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Сообщение отправителю',
            hintStyle: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            contentPadding: EdgeInsets.zero,
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget buildCardSelector(BuildContext context, String label) {
    return Obx(() {
      if (controller.accountsController.accounts.isEmpty) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'У вас нет доступных счетов',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }
      return AnimatedCardDropdown(
        accounts: controller.accountsController.accounts,
        label: label,
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
}

class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({required this.scanWindow, this.borderRadius = 12.0});

  final Rect scanWindow;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          scanWindow,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOver;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final borderRect = RRect.fromRectAndCorners(
      scanWindow,
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
        borderRadius != oldDelegate.borderRadius;
  }
}

class AnalyzeImageFromGalleryButton extends StatelessWidget {
  const AnalyzeImageFromGalleryButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Colors.white,
      icon: const Icon(Icons.image),
      iconSize: 32.0,
      onPressed: () async {
        final ImagePicker picker = ImagePicker();

        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );

        if (image == null) {
          return;
        }

        final BarcodeCapture? barcodes = await controller.analyzeImage(
          image.path,
        );

        if (!context.mounted) {
          return;
        }
      },
    );
  }
}

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    String errorMessage;

    switch (error.errorCode) {
      case MobileScannerErrorCode.controllerUninitialized:
        errorMessage = 'Controller not ready.';
      case MobileScannerErrorCode.permissionDenied:
        errorMessage = 'Permission denied';
      case MobileScannerErrorCode.unsupported:
        errorMessage = 'Scanning is unsupported on this device';
      default:
        errorMessage = 'Generic Error';
        break;
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(errorMessage, style: const TextStyle(color: Colors.white)),
            Text(
              error.errorDetails?.message ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
