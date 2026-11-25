import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/theme_extension.dart';

void main() {
  test('light designer palette uses hex opacity roles', () {
    final theme = AppTheme.lightTheme;
    final c = theme.colorScheme;
    final extra = theme.extension<Extra>()!;

    expect(c.onSurface, const Color(0xFF000000));
    expect(c.onSurfaceVariant, const Color(0x80000000));
    expect(c.primaryContainer, const Color(0x337AE2BF));
    expect(c.onPrimaryContainer, const Color(0xFF000000));
    expect(c.secondaryContainer, const Color(0x6600C588));
    expect(c.onSecondaryContainer, const Color(0x80000000));
    expect(extra.accentContainer, const Color(0xFFC3D600));
    expect(extra.notifications, extra.accentContainer);
    expect(extra.scrimGradientStart, const Color(0x007AE2BF));
    expect(extra.scrimGradientEnd, const Color(0xFF7AE2BF));
    expect(extra.primaryText, c.onSurface);
    expect(extra.secondaryText, c.onSurfaceVariant);
    expect(extra.backgroundGradientStart, extra.scrimGradientStart);
    expect(extra.backgroundGradientEnd, extra.scrimGradientEnd);
  });

  test('dark designer palette uses hex opacity roles', () {
    final theme = AppTheme.darkTheme;
    final c = theme.colorScheme;
    final extra = theme.extension<Extra>()!;

    expect(c.onSurface, const Color(0xFFFFFFFF));
    expect(c.onSurfaceVariant, const Color(0x80FFFFFF));
    expect(c.primaryContainer, const Color(0x33193028));
    expect(c.onPrimaryContainer, const Color(0xFFFFFFFF));
    expect(c.secondaryContainer, const Color(0x337AE2BF));
    expect(c.onSecondaryContainer, const Color(0x80FFFFFF));
    expect(extra.accentContainer, const Color(0xFFC3D600));
    expect(extra.notifications, extra.accentContainer);
    expect(extra.scrimGradientStart, const Color(0x00193028));
    expect(extra.scrimGradientEnd, const Color(0xFF193028));
    expect(extra.primaryText, c.onSurface);
    expect(extra.secondaryText, c.onSurfaceVariant);
    expect(extra.backgroundGradientStart, extra.scrimGradientStart);
    expect(extra.backgroundGradientEnd, extra.scrimGradientEnd);
  });
}
