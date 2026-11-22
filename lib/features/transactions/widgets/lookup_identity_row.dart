import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Dots cycle as `.` → `..` → `...` → `.` once per tick.
String lookupDots(int tick) => '.' * ((tick % 3) + 1);

class LookupIdentityRow extends StatelessWidget {
  const LookupIdentityRow({
    super.key,
    required this.loading,
    required this.fallbackText,
    this.fullName,
    this.initials,
  });

  final bool loading;
  final String fallbackText;
  final String? fullName;
  final String? initials;

  static const double avatarSize = 32;
  static const double rowHeight = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: avatarSize,
                    height: avatarSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : initials?.isEmpty == true || initials == null
                ? null
                : CircleAvatar(
                    key: const ValueKey('avatar'),
                    radius: avatarSize / 2,
                    child: Text(
                      initials ?? '',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
          ),
          if (initials?.isNotEmpty == true || loading)
            const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: loading
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedLookupDots(
                        key: const ValueKey('dots'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fullName ?? fallbackText,
                        key: ValueKey(fullName ?? fallbackText),
                        textAlign: TextAlign.left,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fullName == null
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.75,
                                )
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
        ],
      ),
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
    return Text(
      lookupDots(_tick),
      textAlign: TextAlign.left,
      style: widget.style,
      overflow: TextOverflow.ellipsis,
    );
  }
}
