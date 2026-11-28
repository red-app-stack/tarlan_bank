import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show LiquidGlassEngine, LiquidGlassLens, LiquidGlassShape, LiquidGlassStyle;
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() => LiquidGlassEngine.liteGlassOnSkia = true);

  testWidgets('glass bars keep the Material Scaffold layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: LiquidGlassLens(
                  style: const LiquidGlassStyle(
                    shape: LiquidGlassShape.squircle(cornerRadius: 24),
                  ),
                  child: const SizedBox(height: 44, child: TextField()),
                ),
              ),
            ),
          ),
          body: const Center(child: Text('Body')),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: LiquidGlassLens(
                style: const LiquidGlassStyle(
                  shape: LiquidGlassShape.squircle(cornerRadius: 24),
                ),
                child: const SizedBox(height: 64, child: Text('Bar')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
