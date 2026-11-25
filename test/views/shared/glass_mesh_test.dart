import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/glass.dart';
import 'package:tarlan_bank/views/shared/mesh_background.dart';

void main() {
  testWidgets('mesh background with glass bars paints and responds to taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MeshBackground(
          seed: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            extendBodyBehindAppBar: true,
            appBar: const GlassAppBar(title: Text('Title')),
            body: Center(
              child: GlassCard(onTap: () {}, child: const Text('Tap me')),
            ),
            bottomNavigationBar: const GlassSurface(
              child: SizedBox(height: 64),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('mesh colors cover the top half then fade to surface', () {
    const cs = ColorScheme.light(
      primary: Color(0xFF00AB75),
      surface: Color(0xFFF5F5F5),
    );
    final spec = MeshSpec.fromScheme(cs, seed: 1);
    final cols = spec.cols;
    expect(spec.rows, 5);
    expect(spec.points[4 * cols].dy, closeTo(1.0, 1e-9));

    double diffFromSurface(Color c) =>
        (c.r - cs.surface.r).abs() * 255 +
        (c.g - cs.surface.g).abs() * 255 +
        (c.b - cs.surface.b).abs() * 255;

    final top = spec.colors.sublist(0, cols).map(diffFromSurface).toList();
    expect(
      top.reduce(math.max) - top.reduce(math.min),
      greaterThan(20),
      reason: 'the bloom should be asymmetric',
    );

    for (var r = 0; r < 3; r++) {
      final strongest = spec.colors
          .sublist(r * cols, r * cols + cols)
          .map(diffFromSurface)
          .reduce(math.max);
      expect(strongest, greaterThan(20), reason: 'row $r should be coloured');
    }
    for (var r = 3; r < 5; r++) {
      for (final c in spec.colors.sublist(r * cols, r * cols + cols)) {
        expect(
          diffFromSurface(c),
          lessThan(20),
          reason: 'row $r should be surface',
        );
      }
    }
  });
}
