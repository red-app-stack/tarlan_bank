import 'package:material_ui/material_ui.dart';

/// Plain (GetX-free) state + formatting for the transfer amount field.
/// Owns its controllers; the owning State calls [dispose] in its own dispose.
class TransferAmountController {
  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode();

  String amount = '';
  String formatted = '0';
  String previous = '';

  static const int maxTransferAmount = 2000000;

  double get parsed =>
      amount.isEmpty ? 0 : double.tryParse(amount.replaceAll(',', '.')) ?? 0;

  bool get isEmpty => amount.isEmpty || parsed == 0;

  void initialize() {
    text.text = '0';
    update('0', () {});
  }

  void update(String value, void Function() notify) {
    const int maxTransferAmount = TransferAmountController.maxTransferAmount;
    final normalized = value.replaceAll('.', ',');
    final parts = normalized.split(',');
    var integerPart = parts[0].replaceAll(RegExp(r'\D'), '');
    var decimalPart = parts.length > 1
        ? parts[1].replaceAll(RegExp(r'\D'), '')
        : '';
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    if (integerPart.isEmpty) {
      amount = '';
      formatted = '0';
      text.value = TextEditingValue(
        text: '0',
        selection: const TextSelection.collapsed(offset: 1),
      );
      notify();
      return;
    }

    var number = int.tryParse(integerPart) ?? 0;
    if (number > maxTransferAmount) {
      number = int.tryParse(previous.split(',')[0]) ?? 0;
      var formattedValue = _format(number);
      if (normalized.contains(',')) formattedValue += ',$decimalPart';
      _setControllerValue(formattedValue);
      notify();
      return;
    }

    var formattedValue = _format(number);
    if (normalized.contains(',')) formattedValue += ',$decimalPart';
    amount =
        number.toString() + (decimalPart.isNotEmpty ? ',$decimalPart' : '');
    formatted = formattedValue;
    previous = amount;
    _setControllerValue(formattedValue);
    notify();
  }

  String _format(int number) => number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]} ',
  );

  void _setControllerValue(String formattedValue) {
    final oldCursor = text.selection.start;
    final distanceFromEnd = text.text.length - oldCursor;
    final offset = formattedValue.length - distanceFromEnd;
    text.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: offset < 0
            ? 0
            : (offset > formattedValue.length ? formattedValue.length : offset),
      ),
    );
  }

  void focusEnd() {
    text.selection = TextSelection.fromPosition(
      TextPosition(offset: text.text.length),
    );
    focus.requestFocus();
  }

  void dispose() {
    text.dispose();
    focus.dispose();
  }
}
