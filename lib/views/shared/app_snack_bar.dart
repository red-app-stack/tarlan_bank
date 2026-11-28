import 'package:material_ui/material_ui.dart';

import 'dart:async';

void showAppSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  IconData? icon,
  Duration duration = const Duration(seconds: 4),
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Color? backgroundColor,
  Color? textColor,
  Color? titleColor,
  double? elevation,
  double? borderRadius,
  String? actionLabel,
  VoidCallback? onActionPressed,
  bool fromTop = false,
  double? endPositionOffset,
  Duration animationDuration = const Duration(milliseconds: 400),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final bg = backgroundColor ?? colorScheme.surfaceContainerHigh;
  final txt = textColor ?? colorScheme.onSurface;
  final ttl =
      titleColor ?? (title != null ? colorScheme.onSurfaceVariant : txt);
  final endPositionOffset0 = fromTop
      ? endPositionOffset ?? 2
      : endPositionOffset == null
      ? 0.0
      : -endPositionOffset;

  final snackBarContent = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null)
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 2),
          child: Icon(icon, color: txt),
        ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(color: ttl),
              ),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: txt),
            ),
          ],
        ),
      ),
      if (actionLabel != null && onActionPressed != null)
        TextButton(
          onPressed: onActionPressed,
          child: Text(
            actionLabel,
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
    ],
  );

  final overlayEntry = OverlayEntry(
    builder: (context) => _TopBottomSnackBar(
      content: snackBarContent,
      backgroundColor: bg,
      elevation: elevation ?? 8,
      borderRadius: borderRadius ?? 16,
      margin:
          margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: padding ?? const EdgeInsets.all(16),
      fromTop: fromTop,
      endPositionOffset: endPositionOffset0,
      animationDuration: animationDuration,
      displayDuration: duration,
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

class _TopBottomSnackBar extends StatefulWidget {
  final Widget content;
  final Color backgroundColor;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final bool fromTop;
  final double endPositionOffset;
  final Duration animationDuration;
  final Duration displayDuration;

  const _TopBottomSnackBar({
    super.key,
    required this.content,
    required this.backgroundColor,
    required this.elevation,
    required this.borderRadius,
    required this.margin,
    required this.padding,
    required this.fromTop,
    required this.endPositionOffset,
    required this.animationDuration,
    required this.displayDuration,
  });

  @override
  _TopBottomSnackBarState createState() => _TopBottomSnackBarState();
}

class _TopBottomSnackBarState extends State<_TopBottomSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    final Offset startOffset = widget.fromTop
        ? const Offset(0.0, -1)
        : const Offset(0.0, 1);

    final Offset endOffset = Offset(0.0, widget.endPositionOffset);

    _offsetAnimation = Tween<Offset>(begin: startOffset, end: endOffset)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
        );

    _controller.forward();

    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        if (context.owner != null) {
          if (context.findRenderObject() != null) {
            final overlay = Overlay.of(context);
          }
        }
      }
    });
  }

  void removeOverlayEntry() {
    if (mounted) {
      OverlayEntry? entry;
      context.visitAncestorElements((element) {
        if (element.renderObject?.debugCreator is OverlayEntry) {
          entry = element.renderObject?.debugCreator as OverlayEntry;
          return false;
        }
        return true;
      });
      entry?.remove();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
    removeOverlayEntry();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.fromTop
        ? Alignment.topCenter
        : Alignment.bottomCenter;

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: widget.margin,
            child: LimitedBox(
              maxWidth: MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Padding(padding: widget.padding, child: widget.content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
