import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Dots cycle as `.` → `..` → `...` → `.` once per tick.
String lookupDots(int tick) => '.' * ((tick % 3) + 1);

enum LookupPhase { empty, loading, found, notFound }

class LookupIdentityRow extends StatelessWidget {
  const LookupIdentityRow({
    super.key,
    required this.phase,
    required this.fallbackText,
    this.fullName,
    this.initials,
  });

  final LookupPhase phase;
  final String fallbackText;
  final String? fullName;
  final String? initials;

  static const double avatarSize = 32;
  static const double rowHeight = 40;
  static const double gap = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: rowHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildPhase(theme),
      ),
    );
  }

  Widget _buildPhase(ThemeData theme) {
    switch (phase) {
      case LookupPhase.loading:
        return _slot(
          key: const ValueKey('loading'),
          theme: theme,
          avatar: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          text: AnimatedLookupDots(style: theme.textTheme.bodyMedium),
        );
      case LookupPhase.found:
        return _slot(
          key: const ValueKey('found'),
          theme: theme,
          avatar: CircleAvatar(
            radius: avatarSize / 2,
            child: Text(initials ?? '', style: theme.textTheme.labelLarge),
          ),
          text: Text(
            fullName ?? fallbackText,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case LookupPhase.notFound:
      case LookupPhase.empty:
        return _slot(
          key: ValueKey(phase),
          theme: theme,
          text: Text(
            fallbackText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }

  Widget _slot({
    required Key key,
    required ThemeData theme,
    Widget? avatar,
    required Widget text,
  }) {
    return Row(
      key: key,
      children: [
        SizedBox(width: avatarSize, height: avatarSize, child: avatar),
        const SizedBox(width: gap),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: text),
        ),
      ],
    );
  }
}

class AnimatedLookupDots extends StatefulWidget {
  const AnimatedLookupDots({super.key, this.style});

  final TextStyle? style;

  @override
  State<AnimatedLookupDots> createState() => _AnimatedLookupDotsState();
}

class _AnimatedLookupDotsState extends State<AnimatedLookupDots> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: Text(
        lookupDots(_tick),
        key: ValueKey<int>(_tick),
        textAlign: TextAlign.left,
        style: widget.style,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
