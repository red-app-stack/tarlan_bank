import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassEngine, LiquidGlassLens;
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:tarlan_bank/views/main/main_shell.dart';

void main() {
  setUpAll(() => LiquidGlassEngine.liteGlassOnSkia = true);

  Widget bar({int selected = 0}) {
    return SizedBox(
      width: 360,
      height: GlassSelectionBar.barHeight,
      child: GlassSelectionBar(
        selected: selected,
        itemCount: 3,
        theme: AppTheme.lightTheme,
        itemBuilder: (index) => Text('tab $index'),
      ),
    );
  }

  testWidgets('bar glass and sliding capsule are unclipped siblings', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: bar()));
    await tester.pumpAndSettle();

    final stack = find.byWidgetPredicate(
      (widget) =>
          widget is Stack &&
          widget.clipBehavior == Clip.none &&
          widget.children.length >= 3,
    );
    expect(stack, findsOneWidget);

    final lenses = find.descendant(
      of: stack,
      matching: find.byType(LiquidGlassLens),
    );
    expect(lenses, findsNWidgets(2));
    expect(
      find.ancestor(
        of: find.byType(LiquidGlassLens),
        matching: find.byType(LiquidGlassLens),
      ),
      findsNothing,
    );

    for (final label in ['tab 0', 'tab 1', 'tab 2']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.height == GlassSelectionBar.barHeight,
      ),
      findsWidgets,
    );
  });

  testWidgets('capsule keeps the easeOutBack overshoot animation', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: bar(selected: 2)));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedPositioned &&
            widget.curve == Curves.easeOutBack &&
            widget.duration == const Duration(milliseconds: 340),
      ),
      findsOneWidget,
    );
  });
}
