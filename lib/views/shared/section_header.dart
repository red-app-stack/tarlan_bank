import 'package:flutter_svg/svg.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, LiquidRoundedSuperellipse;
import 'package:material_ui/material_ui.dart';

import '../../utils/themes/glass_settings.dart';

/// App-wide section header: title on the left, glass pill action on the right.
/// The icon sits to the right of the label and is 12px across this family.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
    this.iconSize = 12,
    this.buttonHeight = 36,
  });

  final String title;
  final String buttonLabel;
  final String buttonIcon;
  final VoidCallback onPressed;
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

    return Row(
      spacing: 10,
      children: [
        Expanded(child: Text(title, style: titleStyle)),
        GlassContainer(
          height: buttonHeight,
          shape: const LiquidRoundedSuperellipse(borderRadius: 18),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          settings: themedGlassSettings(
            theme,
            accent: theme.colorScheme.secondaryContainer,
          ),
          useOwnLayer: false,
          quality: scrollGlassQuality,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonLabel,
                    style: (theme.textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                  SizedBox(width: iconSize / 2),
                  SvgPicture.asset(
                    buttonIcon,
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
      ],
    );
  }
}
