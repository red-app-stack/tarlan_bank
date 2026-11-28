import 'package:material_ui/material_ui.dart';

class HorizontalExamples extends StatefulWidget {
  final List<String> questions;
  final ValueChanged<String> onSelected;
  final bool visible;

  const HorizontalExamples({
    super.key,
    required this.questions,
    required this.onSelected,
    this.visible = true,
  });

  @override
  State<HorizontalExamples> createState() => _HorizontalExamplesState();
}

class _HorizontalExamplesState extends State<HorizontalExamples> {
  bool _isPaused = false;

  void _handleTap(String question) {
    if (!_isPaused) {
      setState(() => _isPaused = true);
    }
    widget.onSelected(question);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPaused) {
        setState(() => _isPaused = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const SizedBox.shrink();

    // Split questions into two rows
    final int splitIndex = (widget.questions.length / 2).ceil();
    final List<String> leftQuestions = widget.questions.sublist(0, splitIndex);
    final List<String> rightQuestions = widget.questions.sublist(splitIndex);

    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            _MarqueeRow(
              items: leftQuestions,
              isReversed: false,
              isPaused: _isPaused,
              onTap: _handleTap,
            ),
            const SizedBox(height: 8),
            _MarqueeRow(
              items: rightQuestions,
              isReversed: true,
              isPaused: _isPaused,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// A highly optimized, hardware-accelerated marquee row
class _MarqueeRow extends StatefulWidget {
  final List<String> items;
  final bool isReversed;
  final bool isPaused;
  final ValueChanged<String> onTap;

  const _MarqueeRow({
    required this.items,
    required this.isReversed,
    required this.isPaused,
    required this.onTap,
  });

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final GlobalKey _rowKey = GlobalKey();
  double _rowWidth = 0;

  @override
  void initState() {
    super.initState();
    // Adjust duration to control scroll speed (e.g., 20-30 seconds for a smooth glide)
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: 25),
        )..addStatusListener((status) {
          // Manual looping instead of .repeat(): lets us resume mid-cycle later
          // without snapping back to the start (see _startAnimation below).
          if (status == AnimationStatus.completed) {
            _controller.value = 0;
            if (!widget.isPaused) _controller.forward();
          }
        });
    _startAnimation();

    // Measure the width after the first frame to calculate seamless loop offset
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidth());
  }

  void _measureWidth() {
    final renderBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      // We divide by 2 because the row contains two duplicated sets of items
      final halfWidth = renderBox.size.width / 2;
      if (_rowWidth != halfWidth) {
        setState(() => _rowWidth = halfWidth);
      }
    }
  }

  void _startAnimation() {
    if (widget.isPaused) {
      _controller.stop(); // keeps current value, freezes in place
    } else if (!_controller.isAnimating) {
      // forward(from: value) resumes smoothly from wherever we stopped.
      // (Deliberately NOT using .repeat() here — it always restarts at the
      // lower bound, which is what caused the visible "snap back" jump
      // every time the row resumed after a tap-pause.)
      _controller.forward(from: _controller.value);
    }
  }

  @override
  void didUpdateWidget(covariant _MarqueeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPaused != widget.isPaused) _startAnimation();
    if (oldWidget.items != widget.items) {
      _rowWidth = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidth());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Build the chips ONCE. This list is passed to AnimatedBuilder's `child`
    // parameter so it does NOT rebuild on every animation frame.
    final itemWidgets = widget.items.map((q) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => widget.onTap(q),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Center(child: Text(q, style: theme.textTheme.bodySmall)),
            ),
          ),
        ),
      );
    }).toList();

    return SizedBox(
      height: 36,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_rowWidth == 0) return child!;

            // Calculate pixel offset based on animation progress (0.0 to 1.0)
            final offset = _controller.value * _rowWidth;
            final dx = widget.isReversed ? offset - _rowWidth : -offset;

            // Transform.translate is evaluated on the Render Thread (GPU accelerated)
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: OverflowBox(
            // Without this, the Row is clamped to the parent's bounded
            // width whenever its true (2x) content is wider than the
            // viewport — which both throws the RenderFlex overflow you
            // were seeing AND makes _measureWidth() read a clamped,
            // too-small size, throwing off the loop-reset offset above.
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              key: _rowKey,
              mainAxisSize: MainAxisSize.min,
              children: [...itemWidgets],
            ),
          ),
        ),
      ),
    );
  }
}
