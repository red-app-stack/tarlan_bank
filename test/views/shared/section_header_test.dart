import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassEngine, LiquidGlassLens;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/section_header.dart';

void main() {
  setUpAll(() => LiquidGlassEngine.liteGlassOnSkia = true);

  testWidgets('section header shows title and right-aligned 12px action icon', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: 'Accounts',
            buttonLabel: 'Open New',
            buttonIcon: 'assets/icons/ic_add.svg',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Open New'), findsOneWidget);
    final icon = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(icon.width, 12);

    await tester.tap(find.text('Open New'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('section header without action renders only the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SectionHeader(title: 'Debit balance')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Debit balance'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
    final style = tester.widget<Text>(find.text('Debit balance')).style;
    expect(style?.fontSize, 12);
    expect(style?.height, closeTo(16 / 12, 0.001));
    expect(
      style?.color,
      Theme.of(tester.element(find.text('Debit balance')))
          .colorScheme
          .onSurface,
    );
  });
}
