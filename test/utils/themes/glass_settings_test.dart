import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';

void main() {
  test('scroll glass is simplified, shell glass stays premium', () {
    expect(shellGlassQuality, GlassQuality.premium);
    expect(scrollGlassQuality, GlassQuality.standard);
  });

  test('simplified glass keeps the diagonal light angle and themed colour', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final settings = themedGlassSettings(theme);
      expect(settings.lightAngle, diagonalGlassLightAngle);
      expect(settings.glassColor, theme.colorScheme.primaryContainer);
    }
  });
}
