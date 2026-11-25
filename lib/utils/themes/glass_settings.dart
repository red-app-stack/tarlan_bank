import 'dart:math' as math;

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show LiquidGlassSettings;
import 'package:material_ui/material_ui.dart';

import 'theme_extension.dart';

/// Fallback keep the notification accent in sync with AppColorsLight/Dark.
const Color fallbackNotificationColor = Color(0xFFC3D600);

/// 45° light axis (upper-left). The ios27 presets default to pi/2 (top) in
/// light and -pi/2 (bottom) in dark, which is why the rim only reads as a
/// top/bottom band; this rotates rimShade/rimLight and the specular with it.
const double diagonalGlassLightAngle = 0.75 * math.pi;

/// Glass tint for a surface, mixed from the theme's configurable base tint and
/// a semantic accent. Passing [accent] lets one control (e.g. notifications)
/// borrow its own colour while all other glass keeps the primary accent.
LiquidGlassSettings themedGlassSettings(
  ThemeData theme, {
  Color? accent,
  double accentMix = 0.02,
  double? alpha,
}) {
  final extra = theme.extension<Extra>();
  final isDark = theme.brightness == Brightness.dark;
  final base = accent ?? theme.colorScheme.primaryContainer;
  final preset = isDark
      ? LiquidGlassSettings.ios27Dark
      : LiquidGlassSettings.ios27Light;
  return preset.copyWith(glassColor: base, lightAngle: diagonalGlassLightAngle);
}

/// The notification accent, read from the active theme with a safe fallback.
Color notificationColor(ThemeData theme) {
  final extra = theme.extension<Extra>();
  return extra?.accentContainer ??
      extra?.notifications ??
      fallbackNotificationColor;
}
