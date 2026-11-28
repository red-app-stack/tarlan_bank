import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show
        LiquidGlassBlurMethod,
        LiquidGlassConfiguration,
        LiquidGlassEngine,
        LiquidGlassLight,
        LiquidGlassShaders,
        LiquidGlassShape,
        LiquidGlassStyle;
import 'package:material_ui/material_ui.dart';

import 'theme_extension.dart';

/// Fallback keep the notification accent in sync with AppColorsLight/Dark.
const Color fallbackNotificationColor = Color(0xFFC3D600);

/// The light axis, in DEGREES (liquid_glass_easy's unit): 45° runs from the
/// upper-left rim to the lower-right rim, so the specular and the glow both
/// read diagonally instead of as a top/bottom band.
const double diagonalGlassLightAngle = 45;

/// Blur for floating chrome (top bar, bottom nav). It sits over content that
/// scrolls underneath, so it needs a little frost to stay legible. The guide
/// asks for 2-3; the style's tint carries the rest of the frost.
const double shellGlassBlur = 2.5;

/// Blur for glass that lives in the page body, inside the page's
/// `LiquidGlassBatch`. Only the mesh sits behind it, and a mesh is already
/// low-frequency, so a blur would change nothing you can see. Zero is the
/// cheapest setup in the efficiency guide: one shared read, no blur pass.
const double scrollGlassBlur = 0;

/// Light, clear bend at the rim: 1.0 is no bending, 1.02 a clear lens edge.
const double glassRefractionIndex = 1.04;

/// How far in from the outline the bend reaches, in logical pixels.
const double glassRefractionWidth = 16;

/// One-time glass setup, called from `main()` before `runApp`.
///
/// * Skia and the web ship lite glass (frost, tint, lit rim: no shader, no
///   capture, no `LiquidGlassView` to maintain). Impeller, the default on
///   current Android and iOS, runs the full refracting lens.
/// * Blur runs inside the lens shader, in a batch and out of one, so a blurred
///   glass costs no backdrop pass of its own and a batch keeps its single read.
/// * The shaders compile before the first frame, so the first glass on screen
///   is already glass.
Future<void> initGlass() async {
  LiquidGlassEngine.liteGlassOnSkia = true;
  LiquidGlassConfiguration.batchBlurMethod = LiquidGlassBlurMethod.shader;
  LiquidGlassConfiguration.blurMethod = LiquidGlassBlurMethod.shader;
  try {
    await LiquidGlassShaders.ensureLoaded();
  } catch (error) {
    // A failed warm-up must not block boot: the first lens retries the load
    // and draws lite glass until it lands.
    debugPrint('Glass shader warm-up failed: $error');
  }
}

/// The glass look for a surface: [shape] and a fixed tint taken from the
/// theme's `primaryContainer` (or [accent]), lit along
/// [diagonalGlassLightAngle].
///
/// The tint is a plain colour and `adaptivity` is deliberately left off. With
/// adaptivity on, the glass re-samples the pixels behind it and flips its tint
/// as the background changes, which is exactly what must not happen to glass
/// that scrolls over the uneven mesh. Pass [blur] explicitly: [shellGlassBlur]
/// for chrome (the default), [scrollGlassBlur] for body glass.
LiquidGlassStyle themedGlassStyle(
  ThemeData theme, {
  required LiquidGlassShape shape,
  Color? accent,
  double blur = shellGlassBlur,
}) {
  return LiquidGlassStyle(
    shape: shape,
    color: accent ?? theme.colorScheme.primaryContainer,
    blur: blur,
    refractionIndex: glassRefractionIndex,
    refractionWidth: glassRefractionWidth,
    specular: const LiquidGlassLight.specular(angle: diagonalGlassLightAngle),
    glow: const LiquidGlassLight.glow(angle: diagonalGlassLightAngle),
  );
}

/// The notification accent, read from the active theme with a safe fallback.
Color notificationColor(ThemeData theme) {
  final extra = theme.extension<Extra>();
  return extra?.accentContainer ??
      extra?.notifications ??
      fallbackNotificationColor;
}
