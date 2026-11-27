import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/section_header.dart';

void main() {
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
}
