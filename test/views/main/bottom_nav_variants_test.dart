import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show
        LiquidGlassEngine,
        LiquidGlassLens,
        LiquidGlassPillMode,
        LiquidGlassShape,
        LiquidGlassTabBar,
        LiquidGlassTabBarItem,
        LiquidGlassTabPillStyle;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';

void main() {
  setUpAll(() => LiquidGlassEngine.liteGlassOnSkia = true);

  testWidgets('package glass tab bar renders three 64pt tabs', (tester) async {
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) => LiquidGlassTabBar(
              items: const [
                LiquidGlassTabBarItem(icon: Icons.home, label: 'Home'),
                LiquidGlassTabBarItem(icon: Icons.qr_code, label: 'QR'),
                LiquidGlassTabBarItem(icon: Icons.menu, label: 'Services'),
              ],
              selectedIndex: 0,
              onChanged: (_) {},
              width: constraints.maxWidth,
              height: 64,
              margin: EdgeInsets.zero,
              style: themedGlassStyle(
                theme,
                shape: const LiquidGlassShape.continuousRoundedRectangle(
                  cornerRadius: 64,
                ),
              ),
              pillStyle: LiquidGlassTabPillStyle(
                mode: LiquidGlassPillMode.none,
                color: theme.colorScheme.primaryContainer,
                animated: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('QR'), findsWidgets);
    expect(find.text('Services'), findsWidgets);
    expect(find.byType(LiquidGlassLens), findsOneWidget);
    expect(tester.getSize(find.byType(LiquidGlassTabBar)).height, 64);
  });
}
