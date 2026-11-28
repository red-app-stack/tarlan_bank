import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart' show LiquidGlassShape;

import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';

void main() {
  const shape = LiquidGlassShape.squircle(cornerRadius: 28);

  test('body glass is the cheap setup, chrome keeps a light blur', () {
    // Efficiency guide: a batch with no blur is the cheapest glass, and the
    // blur that is used stays in the 2-5 range.
    expect(scrollGlassBlur, 0);
    expect(shellGlassBlur, inInclusiveRange(2, 5));
  });

  test('themed glass is a fixed tint, lit diagonally, never adaptive', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final style = themedGlassStyle(theme, shape: shape);
      expect(style.color, theme.colorScheme.primaryContainer);
      expect(style.shape, shape);
      expect(style.blur, shellGlassBlur);
      expect(style.specular?.angle, diagonalGlassLightAngle);
      expect(style.glow?.angle, diagonalGlassLightAngle);
      // Adaptivity is what re-tints glass from the pixels behind it.
      expect(style.adaptivity, isNull);
      expect(style.liteGlass, isFalse);
    }
  });

  test('accent and blur overrides reach the style', () {
    final theme = AppTheme.lightTheme;
    final style = themedGlassStyle(
      theme,
      shape: shape,
      accent: theme.colorScheme.secondaryContainer,
      blur: scrollGlassBlur,
    );
    expect(style.color, theme.colorScheme.secondaryContainer);
    expect(style.blur, scrollGlassBlur);
  });
}
