import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/utils/themes/app_colors_dark.dart';
import 'package:tarlan_bank/utils/themes/app_colors_light.dart';
import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';

void main() {
  test('light designer palette uses hex opacity roles', () {
    final colors = AppColorsLight();
    final theme = AppTheme.lightTheme;
    final c = theme.colorScheme;
    final extra = theme.extension<Extra>()!;

    expect(colors.onSurface, const Color(0xFF000000));
    expect(colors.onSurfaceVariant, const Color(0x80000000));
    expect(colors.primaryContainer, const Color(0x337AE2BF));
    expect(colors.onPrimaryContainer, const Color(0xFF000000));
    expect(colors.secondaryContainer, const Color(0x6600C588));
    expect(colors.onSecondaryContainer, const Color(0xFF000000));
    expect(colors.accentContainer, const Color(0xFFC3D600));
    expect(colors.scrimGradientStart, const Color(0x007AE2BF));
    expect(colors.scrimGradientEnd, const Color(0xFF7AE2BF));

    expect(c.onSurface, colors.onSurface);
    expect(c.primaryContainer, colors.primaryContainer);
    expect(c.secondaryContainer, colors.secondaryContainer);
    expect(extra.accentContainer, colors.accentContainer);
    expect(extra.notifications, extra.accentContainer);
    expect(extra.scrimGradientStart, colors.scrimGradientStart);
    expect(extra.scrimGradientEnd, colors.scrimGradientEnd);
    expect(extra.primaryText, colors.onSurface);
    expect(extra.secondaryText, colors.onSurfaceVariant);
    expect(extra.backgroundGradientStart, extra.scrimGradientStart);
    expect(extra.backgroundGradientEnd, extra.scrimGradientEnd);
  });

  test('dark designer palette uses hex opacity roles', () {
    final colors = AppColorsDark();
    final theme = AppTheme.darkTheme;
    final c = theme.colorScheme;
    final extra = theme.extension<Extra>()!;

    expect(colors.onSurface, const Color(0xFFFFFFFF));
    expect(colors.onSurfaceVariant, const Color(0x80FFFFFF));
    expect(colors.primaryContainer, const Color(0x33193028));
    expect(colors.onPrimaryContainer, const Color(0xFFFFFFFF));
    expect(colors.secondaryContainer, const Color(0x337AE2BF));
    expect(colors.onSecondaryContainer, const Color(0xFFFFFFFF));
    expect(colors.accentContainer, const Color(0xFFC3D600));
    expect(colors.scrimGradientStart, const Color(0x00193028));
    expect(colors.scrimGradientEnd, const Color(0xFF193028));

    expect(c.onSurface, colors.onSurface);
    expect(c.primaryContainer, colors.primaryContainer);
    expect(c.secondaryContainer, colors.secondaryContainer);
    expect(extra.accentContainer, colors.accentContainer);
    expect(extra.notifications, extra.accentContainer);
    expect(extra.scrimGradientStart, colors.scrimGradientStart);
    expect(extra.scrimGradientEnd, colors.scrimGradientEnd);
    expect(extra.primaryText, colors.onSurface);
    expect(extra.secondaryText, colors.onSurfaceVariant);
    expect(extra.backgroundGradientStart, extra.scrimGradientStart);
    expect(extra.backgroundGradientEnd, extra.scrimGradientEnd);
  });
}
