import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/utils/themes/glass_settings.dart';

void main() {
  testWidgets('package glass tab bar renders three 64pt tabs', (tester) async {
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GlassTabBar.bottom(
            tabs: const [
              GlassTab(label: 'Home'),
              GlassTab(label: 'QR'),
              GlassTab(label: 'Services'),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            barHeight: 64,
            settings: themedGlassSettings(theme),
            indicatorColor: theme.colorScheme.primaryContainer,
            quality: .premium,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('QR'), findsWidgets);
    expect(find.text('Services'), findsWidgets);
  });
}
