import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/mesh_background.dart';

void main() {
  testWidgets('mesh background paints without exceptions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MeshBackground(
          seed: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: const Center(child: Text('Mesh')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mesh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('mesh colors cover the top then fade to surface', () {
    const cs = ColorScheme.light(
      primary: Color(0xFF00AB75),
      surface: Color(0xFFF5F5F5),
    );
    final spec = MeshSpec.fromScheme(cs, seed: 1);
    final cols = spec.cols;
    expect(spec.rows, 6);
    expect(spec.points[3 * cols].dy, closeTo(0.5, 1e-9));
    expect(spec.points[5 * cols].dy, closeTo(1.0, 1e-9));

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
    for (var r = 4; r < 6; r++) {
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
