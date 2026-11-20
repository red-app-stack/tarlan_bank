import 'package:tarlan_bank/utils/themes/theme_extension.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ListItemDirection { horizontal, vertical }

class ListItem extends StatelessWidget {
  final ListItemDirection direction;
  final String? svgPath;
  final IconData? iconData;
  final String? imagePath;
  final Widget? customLeading;
  final bool showNotification;
  final String title;
  final String? subtitle;
  final String? subtitleSvgPrefix;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;
  final double iconSize;
  final double borderRadius;

  const ListItem({
    super.key,
    required this.direction,
    this.svgPath,
    this.iconData,
    this.imagePath,
    this.customLeading,
    this.showNotification = false,
    required this.title,
    this.subtitle,
    this.subtitleSvgPrefix,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.padding,
    this.iconSize = 36,
    this.borderRadius = 12,
  });

  factory ListItem.horizontal({
    Key? key,
    required String imagePath,
    required String title,
    double? iconSize,
    VoidCallback? onTap,
  }) {
    return ListItem(
      key: key,
      direction: ListItemDirection.horizontal,
      imagePath: imagePath,
      title: title,
      iconSize: iconSize ?? 80,
      onTap: onTap,
      borderRadius: 30,
    );
  }

  // Factory for vertical list items (replaces all vertical variants)
  factory ListItem.vertical({
    Key? key,
    String? svgPath,
    IconData? iconData,
    String? imagePath,
    Widget? customLeading,
    bool showNotification = false,
    required String title,
    String? subtitle,
    String? subtitleSvgPrefix,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = false,
    double iconSize = 36,
    double borderRadius = 12,
  }) {
    return ListItem(
      key: key,
      direction: ListItemDirection.vertical,
      svgPath: svgPath,
      iconData: iconData,
      imagePath: imagePath,
      customLeading: customLeading,
      showNotification: showNotification,
      title: title,
      subtitle: subtitle,
      subtitleSvgPrefix: subtitleSvgPrefix,
      trailing: trailing,
      onTap: onTap,
      showDivider: showDivider,
      iconSize: iconSize,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return direction == ListItemDirection.horizontal
        ? _buildHorizontal(context, theme)
        : _buildVertical(context, theme);
  }

  Widget _buildHorizontal(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashFactory: InkRipple.splashFactory,
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath!,
                      width: iconSize,
                      height: iconSize,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVertical(
    BuildContext context,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashFactory: InkRipple.splashFactory,
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (customLeading != null)
                    customLeading!
                  else
                    _buildLeadingWithNotification(theme),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null || subtitleSvgPrefix != null) ...[
                          const SizedBox(height: 4),
                          _buildSubtitle(theme),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: (padding ?? const EdgeInsets.symmetric(horizontal: 16))
                    .horizontal
                    .isNaN
                ? 16
                : (padding ?? const EdgeInsets.symmetric(horizontal: 16))
                        .horizontal /
                    2,
            endIndent: (padding ?? const EdgeInsets.symmetric(horizontal: 16))
                    .horizontal
                    .isNaN
                ? 16
                : (padding ?? const EdgeInsets.symmetric(horizontal: 16))
                        .horizontal /
                    2,
            color: theme.colorScheme.secondaryContainer,
          ),
      ],
    );
  }

  Widget _buildLeadingWithNotification(ThemeData theme) {
    return Stack(
      alignment: Alignment.topRight,
      clipBehavior: Clip.none,
      children: [
        _buildLeadingIcon(theme),
        if (showNotification)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.extension<Extra>()!.notifications,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath!,
        width: iconSize,
        height: iconSize,
        colorFilter:
            ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn),
      );
    }
    if (iconData != null) {
      return Icon(
        iconData!,
        size: iconSize,
        color: theme.colorScheme.primary,
      );
    }
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: iconSize,
        height: iconSize,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubtitle(ThemeData theme) {
    if (subtitleSvgPrefix != null) {
      return Row(
        children: [
          SvgPicture.asset(
            subtitleSvgPrefix!,
            width: 30,
            height: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle ?? '',
              style: theme.textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(
      subtitle ?? '',
      style: theme.textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
