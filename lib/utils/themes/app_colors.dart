import 'package:material_ui/material_ui.dart';

/// Designer palette is: onSurface, onSurfaceVariant, primaryContainer /
/// onPrimaryContainer (container), secondaryContainer / onSecondaryContainer
/// (container-secondary / on-container-variant), accentContainer and the
/// scrimGradientStart/End pair. Every other field is LEGACY: kept temporarily
/// so existing call sites keep compiling; do not use it in new code.
abstract class AppColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  /// LEGACY alias of [accentContainer]; kept for existing notification call sites.
  final Color notifications;

  /// Canonical accent container (the #C3D600 notification colour).
  final Color accentContainer;

  /// Scrim gradient from fully transparent to opaque, in the same hue.
  final Color scrimGradientStart;
  final Color scrimGradientEnd;

  /// Keep for the glass effect; not part of the designer palette.
  final Color glassTint;
  final Color primaryVariant;
  final Color primaryVariantHigh;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color surface;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color inversePrimary;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color background;
  final Color shadow;

  final Color primaryCardBg;
  final Color primaryCardFg;
  final Color secondaryCardBg;
  final Color secondaryCardFg;
  final Color tertiaryCardBg;
  final Color tertiaryCardFg;
  final Color grayCardBg;
  final Color grayCardFg;
  final Color yellowCardBg;
  final Color yellowCardFg;
  final Color purpleCardBg;
  final Color purpleCardFg;
  final Color goldCardBg;
  final Color goldCardFg;
  final Color redCardBg;
  final Color redCardFg;

  AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.notifications,
    required this.accentContainer,
    required this.scrimGradientStart,
    required this.scrimGradientEnd,
    required this.glassTint,
    required this.primaryVariant,
    required this.primaryVariantHigh,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.inversePrimary,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.background,
    required this.shadow,
    required this.primaryCardBg,
    required this.primaryCardFg,
    required this.secondaryCardBg,
    required this.secondaryCardFg,
    required this.tertiaryCardBg,
    required this.tertiaryCardFg,
    required this.grayCardBg,
    required this.grayCardFg,
    required this.yellowCardBg,
    required this.yellowCardFg,
    required this.purpleCardBg,
    required this.purpleCardFg,
    required this.goldCardBg,
    required this.goldCardFg,
    required this.redCardBg,
    required this.redCardFg,
  });
}
