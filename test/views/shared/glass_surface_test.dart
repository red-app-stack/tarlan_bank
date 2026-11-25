import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, LiquidRoundedSuperellipse;
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('package glass bars keep the Material Scaffold layout', (
    tester,
  ) async {
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
              child: GlassContainer(
                width: double.infinity,
                shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                padding: EdgeInsets.zero,
                child: const SizedBox(height: 44, child: TextField()),
              ),
            ),
          ),
          body: const Center(child: Text('Body')),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8),
            child: GlassContainer(
              width: double.infinity,
              shape: const LiquidRoundedSuperellipse(borderRadius: 24),
              padding: EdgeInsets.zero,
              child: const SizedBox(height: 64, child: Text('Bar')),
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
