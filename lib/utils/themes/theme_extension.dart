import 'package:material_ui/material_ui.dart';

/// Canonical designer tokens live on ColorScheme plus [accentContainer] and
/// the [scrimGradientStart]/[scrimGradientEnd] pair. All other fields are
/// LEGACY and kept only until their call sites are migrated.
class Extra extends ThemeExtension<Extra> {
  final Color? primaryText;
  final Color? secondaryText;
  final Color? tertiaryText;
  final Color? backgroundGradientStart;
  final Color? backgroundGradientEnd;
  final Color? primaryVariant;
  // final Color? background;
  final Color? notifications;
  /// Canonical accent container (#C3D600).
  final Color? accentContainer;
  /// Scrim gradient: transparent to opaque in the same hue.
  final Color? scrimGradientStart;
  final Color? scrimGradientEnd;
  /// Keep for the liquid-glass effect; not part of the designer palette.
  final Color? glassTint;
  final Color? primaryCardBg;
  final Color? primaryCardFg;
  final Color? secondaryCardBg;
  final Color? secondaryCardFg;
  final Color? tertiaryCardBg;
  final Color? tertiaryCardFg;
  final Color? grayCardBg;
  final Color? grayCardFg;
  final Color? yellowCardBg;
  final Color? yellowCardFg;
  final Color? purpleCardBg;
  final Color? purpleCardFg;
  final Color? goldCardBg;
  final Color? goldCardFg;
  final Color? redCardBg;
  final Color? redCardFg;

  Extra({
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.primaryVariant,
    // required this.background,
    required this.notifications,
    required this.accentContainer,
    required this.scrimGradientStart,
    required this.scrimGradientEnd,
    required this.glassTint,
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

  @override
  Extra copyWith(
      {Color? backgroundGradientStart, Color? backgroundGradientEnd}) {
    return Extra(
      primaryText: primaryText ?? primaryText,
      secondaryText: secondaryText ?? secondaryText,
      tertiaryText: tertiaryText ?? tertiaryText,
      backgroundGradientStart:
          backgroundGradientStart ?? backgroundGradientStart,
      backgroundGradientEnd: backgroundGradientEnd ?? backgroundGradientEnd,
      primaryVariant: primaryVariant ?? primaryVariant,
      // background: background ?? background,
      notifications: notifications ?? notifications,
      accentContainer: accentContainer,
      scrimGradientStart: scrimGradientStart,
      scrimGradientEnd: scrimGradientEnd,
      glassTint: glassTint,
      primaryCardBg: primaryCardBg ?? primaryCardBg,
      primaryCardFg: primaryCardFg ?? primaryCardFg,
      secondaryCardBg: secondaryCardBg ?? secondaryCardBg,
      secondaryCardFg: secondaryCardFg ?? secondaryCardFg,
      tertiaryCardBg: tertiaryCardBg ?? tertiaryCardBg,
      tertiaryCardFg: tertiaryCardFg ?? tertiaryCardFg,
      grayCardBg: grayCardBg ?? grayCardBg,
      grayCardFg: grayCardFg ?? grayCardFg,
      yellowCardBg: yellowCardBg ?? yellowCardBg,
      yellowCardFg: yellowCardFg ?? yellowCardFg,
      purpleCardBg: purpleCardBg ?? purpleCardBg,
      purpleCardFg: purpleCardFg ?? purpleCardFg,
      goldCardBg: goldCardBg ?? goldCardBg,
      goldCardFg: goldCardFg ?? goldCardFg,
      redCardBg: redCardBg ?? redCardBg,
      redCardFg: redCardFg ?? redCardFg,
    );
  }

  @override
  Extra lerp(ThemeExtension<Extra>? other, double t) {
    if (other is! Extra) return this;
    return Extra(
      primaryText: primaryText ?? primaryText,
      secondaryText: secondaryText ?? secondaryText,
      tertiaryText: tertiaryText ?? tertiaryText,
      backgroundGradientStart:
          Color.lerp(backgroundGradientStart, other.backgroundGradientStart, t),
      backgroundGradientEnd:
          Color.lerp(backgroundGradientEnd, other.backgroundGradientEnd, t),
      primaryVariant: Color.lerp(primaryVariant, other.primaryVariant, t),
      // background: Color.lerp(background, other.background, t),
      notifications: Color.lerp(notifications, other.notifications, t),
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t),
      scrimGradientStart:
          Color.lerp(scrimGradientStart, other.scrimGradientStart, t),
      scrimGradientEnd: Color.lerp(scrimGradientEnd, other.scrimGradientEnd, t),
      glassTint: Color.lerp(glassTint, other.glassTint, t),
      primaryCardBg: Color.lerp(primaryCardBg, other.primaryCardBg, t),
      primaryCardFg: Color.lerp(primaryCardFg, other.primaryCardFg, t),
      secondaryCardBg: Color.lerp(secondaryCardBg, other.secondaryCardBg, t),
      secondaryCardFg: Color.lerp(secondaryCardFg, other.secondaryCardFg, t),
      tertiaryCardBg: Color.lerp(tertiaryCardBg, other.tertiaryCardBg, t),
      tertiaryCardFg: Color.lerp(tertiaryCardBg, other.tertiaryCardFg, t),
      grayCardBg: Color.lerp(grayCardBg, other.grayCardBg, t),
      grayCardFg: Color.lerp(grayCardFg, other.grayCardFg, t),
      yellowCardBg: Color.lerp(yellowCardBg, other.yellowCardBg, t),
      yellowCardFg: Color.lerp(yellowCardFg, other.yellowCardFg, t),
      purpleCardBg: Color.lerp(purpleCardBg, other.purpleCardBg, t),
      purpleCardFg: Color.lerp(purpleCardFg, other.purpleCardFg, t),
      goldCardBg: Color.lerp(goldCardBg, other.goldCardBg, t),
      goldCardFg: Color.lerp(goldCardFg, other.goldCardFg, t),
      redCardBg: Color.lerp(redCardBg, other.redCardBg, t),
      redCardFg: Color.lerp(redCardFg, other.redCardFg, t),
    );
  }
}
