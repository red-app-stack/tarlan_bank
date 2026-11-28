import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassBatch, LiquidGlassEngine, LiquidGlassLens;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/glass_widget_grid.dart';

void main() {
  setUpAll(() => LiquidGlassEngine.liteGlassOnSkia = true);

  testWidgets('glass widget grid edits, adds and keeps its tiles tappable', (
    tester,
  ) async {
    var taps = 0;
    final items = List.generate(
      6,
      (i) => GlassGridItem(
        id: 'item$i',
        iconPath: 'assets/icons/ic_card.svg',
        title: 'Item $i',
        onTap: () => taps++,
      ),
    );
    final available = [
      ...items,
      GlassGridItem(
        id: 'extra',
        iconPath: 'assets/icons/ic_qr.svg',
        title: 'Extra',
        onTap: () {},
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Same shape as HomeScreen: one batch around the scrollable.
          body: LiquidGlassBatch(
            child: SingleChildScrollView(
              child: GlassWidgetGrid(
                title: 'Widgets',
                editLabel: 'Edit',
                addLabel: 'Add widget',
                items: items,
                availableItems: available,
                rows: 2,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Widgets'), findsOneWidget);
    // Edit button + panel: the grid's whole glass.
    expect(find.byType(LiquidGlassLens), findsNWidgets(2));
    for (var i = 0; i < 6; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Add widget'), findsNothing);

    await tester.tap(find.text('Item 0'));
    await tester.pump();
    expect(taps, 1);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Add widget'), findsOneWidget);

    await tester.tap(find.text('Add widget'));
    await tester.pumpAndSettle();
    expect(find.text('Extra'), findsWidgets);

    await tester.tap(find.text('Extra').last);
    await tester.pumpAndSettle();
    expect(find.text('Extra'), findsOneWidget);
  });
}
