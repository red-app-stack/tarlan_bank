import 'package:material_ui/material_ui.dart';

/// Reapplies a formatted string while keeping the cursor at the same logical
/// digit position instead of jumping to the end.
TextEditingValue applyMaskPreservingSelection({
  required String oldText,
  required String newText,
  required TextSelection selection,
}) {
  final base = _offsetForDigitCount(
    newText,
    _digitCountBefore(oldText, selection.baseOffset),
  );
  final extent = _offsetForDigitCount(
    newText,
    _digitCountBefore(oldText, selection.extentOffset),
  );
  return TextEditingValue(
    text: newText,
    selection: TextSelection(baseOffset: base, extentOffset: extent),
  );
}

int _digitCountBefore(String text, int offset) {
  final end = offset.clamp(0, text.length);
  return text.substring(0, end).replaceAll(RegExp(r'\D'), '').length;
}

int _offsetForDigitCount(String text, int digits) {
  if (digits <= 0) return 0;
  var seen = 0;
  for (var i = 0; i < text.length; i++) {
    if (_isDigit(text.codeUnitAt(i))) {
      seen++;
      if (seen == digits) return i + 1;
    }
  }
  return text.length;
}

bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
