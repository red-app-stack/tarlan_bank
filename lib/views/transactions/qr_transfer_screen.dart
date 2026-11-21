import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
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

class QRTransferScreen extends ConsumerStatefulWidget {
  const QRTransferScreen({super.key, this.transaction});

  /// Optional prefill; null is handled gracefully.
  final BankTransaction? transaction;

  @override
  ConsumerState<QRTransferScreen> createState() => _QRTransferScreenState();
}

class _QRTransferScreenState extends ConsumerState<QRTransferScreen> {
  final TransferAmountController amountCtl = TransferAmountController();
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  MobileScannerController? scannerController;
  bool isScanning = true;
  bool showPaymentView = false;
  Account? selectedAccount;
  bool isAccountDropdownExpanded = false;
  Map<String, dynamic>? scannedData;

  @override
  void initState() {
    super.initState();
    amountCtl.initialize();
    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleInitialTransaction();
    });
  }

  void _handleInitialTransaction() {
    final initial = widget.transaction ?? ref.read(selectedTransactionProvider);
    ref.read(selectedTransactionProvider.notifier).clear();
    if (initial == null) return;
    scannedData = {
      'fullName': '',
      'accountNumber': initial.toAccountId ?? '',
      'currency': initial.currency,
      'amount': initial.amount.toString(),
      'message': initial.message ?? '',
    };
    if (initial.amount > 0) {
      amountCtl.update(initial.amount.toString(), () {});
      amountCtl.text.text = initial.amount.toString();
    }
    if (initial.message != null && initial.message!.isNotEmpty) {
      messageController.text = initial.message!;
    }
    showPaymentView = true;
  }

  @override
  void dispose() {
    amountCtl.dispose();
    messageController.dispose();
    messageFocusNode.dispose();
    scannerController?.dispose();
    super.dispose();
  }

  List<Account> _accounts(List<Account> all) {
    final spendable =
        all
            .where(
              (a) =>
                  a.type == AccountType.current &&
                  a.status == AccountStatus.active,
            )
            .toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));
    return spendable;
  }

  void _syncSelection(List<Account> accounts) {
    final list = _accounts(accounts);
    if (list.isEmpty) {
      if (selectedAccount != null) setState(() => selectedAccount = null);
      return;
    }
    if (selectedAccount == null ||
        !list.any((a) => a.number == selectedAccount!.number)) {
      setState(() => selectedAccount = list.first);
    }
  }

  String _generateQrData() {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).value;
    final acc = selectedAccount;
    if (acc == null) return '';
    return jsonEncode({
      'fullName': profile?.fullName ?? user?.email ?? '',
      'accountNumber': acc.number,
      'currency': acc.currency,
      'amount': amountCtl.amount,
      'message': messageController.text,
    });
  }

  void _processScannedQR(String? rawData) {
    if (rawData == null) return;
    try {
      final data = jsonDecode(rawData) as Map<String, dynamic>;
      if (data['accountNumber'] != null && data['currency'] != null) {
        setState(() {
          scannedData = data;
          showPaymentView = true;
        });
        final rawAmount = data['amount']?.toString() ?? '';
        if (rawAmount.isNotEmpty && (int.tryParse(rawAmount) ?? 0) > 0) {
          amountCtl.update(rawAmount, () {});
          amountCtl.text.text = rawAmount;
        }
        if (data['message'] != null) {
          messageController.text = data['message'].toString();
        }
      }
    } on Object {
      // Invalid QR payloads are ignored (no crash, no snackbar spam).
    }
  }

  Future<void> _submit(AppLocalizations l) async {
    if (selectedAccount == null) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.errorSelectCard,
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
    final target = scannedData?['accountNumber']?.toString();
    if (target == null || target.isEmpty) {
      showAppSnackBar(
        context,
        endPositionOffset: 1,
        title: l.error,
        message: l.recipientNotFound,
      );
      return;
    }

    try {
      final tx = await ref
          .read(transactionsRepositoryProvider)
          .createTransaction(
            fromAccountId: selectedAccount!.number,
            toAccountId: target,
            amount: amountCtl.parsed,
            currency: selectedAccount!.currency,
            type: TransactionType.qrTransfer,
            message: messageController.text.trim().isEmpty
                ? null
                : messageController.text.trim(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final list = _accounts(accounts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSelection(accounts);
    });

    return Scaffold(
      appBar: buildTransferHeader(context, l.qrTransfer),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildToggleSwitch(context, l),
            const SizedBox(height: 16),
            Expanded(
              child: isScanning
                  ? (showPaymentView
                        ? _buildPaymentView(context, l)
                        : _buildScanner(context))
                  : _buildCreator(context, l, list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inverseSurface
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: isScanning
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
                    onTap: () => setState(() => isScanning = true),
                    behavior: HitTestBehavior.opaque,
                    child: _buildToggleOption(
                      context: context,
                      title: l.scan,
                      isSelected: isScanning,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isScanning = false),
                    behavior: HitTestBehavior.opaque,
                    child: _buildToggleOption(
                      context: context,
                      title: l.create,
                      isSelected: !isScanning,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      duration: const Duration(milliseconds: 200),
      child: Center(child: Text(title)),
    );
  }

  Widget _buildPaymentView(BuildContext context, AppLocalizations l) {
    final data = scannedData ?? const <String, dynamic>{};
    final amount = amountCtl.parsed;
    final formattedAmount = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCardSelector(context, l, l.from, selectedAccount),
                  const SizedBox(height: 16),
                  _buildAmountInput(context, l, readOnly: amount != 0),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l.recipient}: ${data['fullName'] ?? ''}'),
                            if ((data['message']?.toString().isNotEmpty ??
                                false))
                              Text('${l.message}: ${data['message']}'),
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                '${l.transferVerb} ${formattedAmount.replaceAll('.', ',')} ${getCurrencySymbol(selectedAccount?.currency)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
      ],
    );
  }

  Widget _buildScanner(BuildContext context) {
    final scanArea =
        (MediaQuery.of(context).size.width < 400 ||
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
    final scanner = scannerController;
    if (scanner == null) return const SizedBox.shrink();

    return Stack(
      children: [
        MobileScanner(
          controller: scanner,
          scanWindow: scanWindow,
          errorBuilder: (context, error) => ScannerErrorWidget(error: error),
          onDetect: (capture) {
            final String? code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) _processScannedQR(code);
          },
        ),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: scanner,
          builder: (context, value, child) =>
              CustomPaint(painter: ScannerOverlay(scanWindow: scanWindow)),
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
                        final XFile? image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image == null) return;
                        final BarcodeCapture? barcodes = await scanner
                            .analyzeImage(image.path);
                        final String? code =
                            barcodes?.barcodes.firstOrNull?.rawValue;
                        if (code != null) _processScannedQR(code);
                      },
                      child: SvgPicture.asset('assets/icons/ic_gallery.svg'),
                    ),
                    GestureDetector(
                      onTap: scanner.toggleTorch,
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

  Widget _buildCreator(
    BuildContext context,
    AppLocalizations l,
    List<Account> accounts,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCardSelector(context, l, l.to, selectedAccount),
          const SizedBox(height: 16),
          _buildAmountInput(context, l, readOnly: false),
          const SizedBox(height: 16),
          _buildMessageInput(context, l),
          const Spacer(),
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
                    l.qrHint,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: PrettyQrView.data(
                        data: _generateQrData(),
                        decoration: const PrettyQrDecoration(
                          image: PrettyQrDecorationImage(
                            image: AssetImage('assets/images/app_icon.png'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Text(
              l.createQrCode,
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

  Widget _buildAmountInput(
    BuildContext context,
    AppLocalizations l, {
    required bool readOnly,
  }) {
    final theme = Theme.of(context);
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
              enabled: !readOnly,
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

  Widget _buildMessageInput(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );
        messageFocusNode.requestFocus();
      },
      child: CustomCard(
        child: TextField(
          focusNode: messageFocusNode,
          controller: messageController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: theme.textTheme.titleLarge,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: l.messageHint,
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

  Widget _buildCardSelector(
    BuildContext context,
    AppLocalizations l,
    String label,
    Account? selected,
  ) {
    final accounts = _accounts(
      ref.watch(accountsProvider).value ?? const <Account>[],
    );
    if (accounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.noAccounts,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }
    return TransferAccountDropdown(
      accounts: accounts,
      label: label,
      selectedAccount: selected,
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
  bool shouldRepaint(ScannerOverlay oldDelegate) =>
      scanWindow != oldDelegate.scanWindow ||
      borderRadius != oldDelegate.borderRadius;
}

class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({super.key, required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final String errorMessage = switch (error.errorCode) {
      MobileScannerErrorCode.controllerUninitialized => 'Controller not ready.',
      MobileScannerErrorCode.permissionDenied => 'Permission denied',
      MobileScannerErrorCode.unsupported =>
        'Scanning is unsupported on this device',
      _ => 'Generic Error',
    };

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
