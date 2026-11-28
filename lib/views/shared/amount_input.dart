import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:material_ui/material_ui.dart';

class AmountNumber extends StatefulWidget {
  final ThemeData theme;
  final String? currency;
  final bool enabled;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;

  const AmountNumber({
    super.key,
    required this.theme,
    this.currency = 'KZT',
    this.enabled = true,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<AmountNumber> createState() => _AmountNumberState();
}

class _AmountNumberState extends State<AmountNumber> {
  double textWidth = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_measureText);
    _measureText();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_measureText);
    super.dispose();
  }

  void _measureText() {
    if (!mounted) return;

    final text = widget.controller.text.isNotEmpty
        ? widget.controller.text
        : '0';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: widget.theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();
    setState(() => textWidth = painter.width);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        widget.focusNode.requestFocus();
      },
      child: SizedBox(
        height: 48,
        child: Stack(
          children: [
            TextField(
              focusNode: widget.focusNode,
              controller: widget.controller,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                hintText: '0',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
            Positioned(
              left: textWidth + 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  getCurrencySymbol(widget.currency!),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
