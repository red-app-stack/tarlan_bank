import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/svg.dart';

class ServiceItemData {
  final String iconPath;
  final String label;
  final String routeArg;

  ServiceItemData(this.iconPath, this.label, this.routeArg);
}

// ServiceItem — fix padding, centering, and vertical overflow
class ServiceItem extends StatelessWidget {
  final String? svgPath;
  final Widget? icon;
  final IconData? iconData;
  final String? imagePath;
  final String? label;
  final double iconSize;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool? expanded;

  const ServiceItem({
    super.key,
    this.label,
    this.svgPath,
    this.icon,
    this.iconData,
    this.imagePath,
    this.iconSize = 32,
    this.onTap,
    this.onDoubleTap,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return expanded == true
        ? Expanded(child: _buildMain(context))
        : _buildMain(context);
  }

  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onDoubleTap: onDoubleTap,
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(30),
        splashFactory: InkRipple.splashFactory,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          // ✅ Symmetric vertical padding instead of top-only,
          //    so content is centered and nothing overflows
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            // ✅ Center vertically within the fixed-height SizedBox
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Icon section
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath!,
                        width: iconSize,
                        height: iconSize,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      )
                    : icon != null
                        ? icon!
                        : iconData != null
                            ? Icon(
                                iconData!,
                                size: iconSize,
                                color: theme.colorScheme.primary,
                              )
                            : imagePath != null
                                ? Image.asset(
                                    imagePath!,
                                    width: iconSize,
                                    height: iconSize,
                                    fit:
                                        BoxFit.contain, // ✅ prevents stretching
                                  )
                                : const SizedBox.shrink(),
              ),
              if (label != null) ...[
                const SizedBox(height: 6),
                Text(
                  label!,
                  maxLines: 2, // ✅ allow wrap before ellipsis
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall, // ✅ smaller fits better
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
