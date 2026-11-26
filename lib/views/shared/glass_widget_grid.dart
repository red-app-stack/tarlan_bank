import 'dart:math' as math;

import 'package:flutter_svg/svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, LiquidRoundedSuperellipse;
import 'package:material_ui/material_ui.dart';

import '../../utils/themes/glass_settings.dart';

/// One tile in a [GlassWidgetGrid]. No glass of its own: it is a plain button
/// living inside the shared glass surface.
class GlassGridItem {
  const GlassGridItem({
    required this.id,
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  final String id;
  final String iconPath;
  final String title;
  final VoidCallback onTap;
}

/// Reusable preset: an outside title + edit button, then one liquid-glass
/// surface holding a 3-wide grid. Edit mode swaps tiles by drag-and-drop and
/// reveals a "+" tile that opens the add-widget dialog.
class GlassWidgetGrid extends StatefulWidget {
  const GlassWidgetGrid({
    super.key,
    required this.title,
    required this.items,
    required this.availableItems,
    this.accent,
    this.rows,
    this.crossAxisCount = 3,
    this.itemHeight = 92,
    this.editLabel = 'Edit',
    this.addLabel = 'Add widget',
  });

  final String title;
  final List<GlassGridItem> items;
  final List<GlassGridItem> availableItems;
  final Color? accent;
  final int? rows;
  final int crossAxisCount;
  final double itemHeight;
  final String editLabel;
  final String addLabel;

  @override
  State<GlassWidgetGrid> createState() => _GlassWidgetGridState();
}

class _GlassWidgetGridState extends State<GlassWidgetGrid> {
  late List<String> _ids;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ids = widget.items.map((item) => item.id).toList();
  }

  @override
  void didUpdateWidget(GlassWidgetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.items.map((item) => item.id).toList();
    if (next.length != _ids.length || !next.every(_ids.contains)) {
      setState(() => _ids = next);
    }
  }

  GlassGridItem? _item(String id) {
    for (final item in [...widget.items, ...widget.availableItems]) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _swap(int from, int to) {
    if (from == to) return;
    setState(() {
      final moved = _ids.removeAt(from);
      _ids.insert(to, moved);
    });
  }

  void _openAddDialog() {
    final remaining = widget.availableItems
        .where((item) => !_ids.contains(item.id))
        .toList();
    if (remaining.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.addLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in remaining)
              ListTile(
                leading: SvgPicture.asset(
                  item.iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                title: Text(item.title),
                onTap: () {
                  setState(() => _ids.add(item.id));
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _editButton(ThemeData theme, Color accent) {
    return GlassContainer(
      width: 92,
      height: 36,
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
      padding: EdgeInsets.zero,
      settings: themedGlassSettings(
        theme,
        accent: theme.colorScheme.secondaryContainer,
        accentMix: 0.65,
        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.4,
      ),
      useOwnLayer: true,
      quality: .premium,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _editing = !_editing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_edit.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSecondaryContainer,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.editLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    GlassGridItem item,
    int index,
    double width,
    ThemeData theme,
    Color accent,
  ) {
    final visual = SizedBox(
      width: width,
      height: widget.itemHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _editing ? null : item.onTap,
          borderRadius: BorderRadius.circular(20),
          splashFactory: InkRipple.splashFactory,
          splashColor: accent.withValues(alpha: 0.38),
          highlightColor: accent.withValues(alpha: 0.18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // color: accent.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        item.iconPath,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              if (_editing)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.drag_handle, size: 16),
                ),
            ],
          ),
        ),
      ),
    );

    if (!_editing) return visual;
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.85, child: visual),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: visual),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) => _swap(details.data, index),
        builder: (context, candidate, rejected) => candidate.isNotEmpty
            ? Opacity(opacity: 0.6, child: visual)
            : visual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accent ?? theme.colorScheme.primaryContainer;
    final visible = _ids.map(_item).whereType<GlassGridItem>().toList();
    final count = visible.length + (_editing ? 1 : 0);
    final needed = math.max(1, (count / widget.crossAxisCount).ceil());
    final rows = math.max(widget.rows ?? needed, needed);
    final height = rows * widget.itemHeight + (rows - 1) * 8 + 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const Spacer(),
            _editButton(theme, accent),
          ],
        ),
        GlassContainer(
          width: double.infinity,
          height: height,
          shape: const LiquidRoundedSuperellipse(borderRadius: 28),
          padding: const EdgeInsets.all(12),
          settings: themedGlassSettings(theme, accent: accent, accentMix: 0.18),
          useOwnLayer: true,
          quality: .minimal,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  (constraints.maxWidth -
                      24 -
                      (widget.crossAxisCount - 1) * 8) /
                  widget.crossAxisCount;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < visible.length; i++)
                    _tile(visible[i], i, width, theme, accent),
                  if (_editing)
                    SizedBox(
                      width: width,
                      height: widget.itemHeight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openAddDialog,
                          borderRadius: BorderRadius.circular(20),
                          splashFactory: InkRipple.splashFactory,
                          splashColor: accent.withValues(alpha: 0.38),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 32,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.addLabel,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
