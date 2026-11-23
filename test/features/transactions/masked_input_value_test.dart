import 'package:material_ui/material_ui.dart';
import 'package:tarlan_bank/features/transactions/widgets/masked_input_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps cursor after the same digit when inserting in the middle', () {
    final result = applyMaskPreservingSelection(
      oldText: '(123) 456-78-90',
      newText: '(123) 945-78-90',
      selection: const TextSelection.collapsed(offset: 8),
    );
    // 4 digits before cursor in both strings -> same offset.
    expect(result.text, '(123) 945-78-90');
    expect(result.selection.baseOffset, 8);
  });

  test('does not jump to the end when deleting a digit in the middle', () {
    final result = applyMaskPreservingSelection(
      oldText: '(123) 456-78-90',
      newText: '(123) 467-89-0',
      selection: const TextSelection.collapsed(offset: 7),
    );
    expect(result.selection.isCollapsed, isTrue);
    expect(result.selection.baseOffset, lessThan(result.text.length));
  });

  test('deleting a separator keeps the cursor past that separator', () {
    final result = applyMaskPreservingSelection(
      oldText: '(123) 456-78-90',
      newText: '123456-78-90',
      selection: const TextSelection.collapsed(offset: 6),
    );
    expect(result.text, '123456-78-90');
    expect(result.selection.baseOffset, 3);
  });

  test('clamps out-of-range selections', () {
    final result = applyMaskPreservingSelection(
      oldText: '',
      newText: '(000) 000-00-00',
      selection: const TextSelection.collapsed(offset: 20),
    );
    expect(result.selection.baseOffset, 0);
  });

  test('preserves a non-collapsed selection', () {
    final result = applyMaskPreservingSelection(
      oldText: '123 456',
      newText: '1234 56',
      selection: const TextSelection(baseOffset: 1, extentOffset: 4),
    );
    expect(result.selection.baseOffset, 1);
    expect(result.selection.extentOffset, 3);
  });
}
