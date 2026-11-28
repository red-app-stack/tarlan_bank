import 'package:flutter_svg/svg.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassLens, LiquidGlassShape;
import 'package:material_ui/material_ui.dart';

import '../../utils/themes/glass_settings.dart';

/// App-wide section header: title on the left, glass pill action on the right.
/// The icon sits to the right of the label and is 12px across this family.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.buttonLabel,
    this.buttonIcon,
    this.onPressed,
    this.iconSize = 12,
    this.buttonHeight = 36,
  });

  final String title;
  final String? buttonLabel;
  final String? buttonIcon;
  final VoidCallback? onPressed;
  final double iconSize;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
          fontSize: 12,
          height: 16 / 12,
          color: theme.colorScheme.onSurface,
        );

    final label = buttonLabel;
    final icon = buttonIcon;
    final action = onPressed;
    final children = <Widget>[Expanded(child: Text(title, style: titleStyle))];
    if (label != null && icon != null && action != null) {
      children.add(
        SizedBox(
          height: buttonHeight,
          child: LiquidGlassLens(
            style: themedGlassStyle(
              theme,
              shape: const LiquidGlassShape.continuousRoundedRectangle(
                cornerRadius: 18,
              ),
              accent: theme.colorScheme.secondaryContainer,
              blur: scrollGlassBlur,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: action,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: (theme.textTheme.bodyMedium ?? const TextStyle())
                            .copyWith(
                              fontSize: 12,
                              height: 16 / 12,
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                      SizedBox(width: iconSize / 2),
                      SvgPicture.asset(
                        icon,
                        width: iconSize,
                        height: iconSize,
                        colorFilter: ColorFilter.mode(
                          cs.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(spacing: 10, children: children);
  }
}
