import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/views/shared/account_card.dart';

void main() {
  testWidgets('account card renders details with configurable aspect ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccountCard(
            imagePath: 'assets/images/accent_image_1.png',
            cardType: 'Debit',
            balance: '1 250 000 ₸',
            accountNumber: '**** 1510',
            expiry: '10/33',
            aspectRatio: 350 / 180,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Debit'), findsOneWidget);
    expect(find.text('1 250 000 ₸'), findsOneWidget);
    expect(find.text('**** 1510'), findsOneWidget);
    expect(find.text('10/33'), findsOneWidget);
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      350 / 180,
    );
  });

  testWidgets('account card reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountCard(
            imagePath: 'assets/images/accent_image_3.png',
            cardType: 'Credit',
            accountNumber: '**** 2048',
            expiry: '04/31',
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Credit'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('account card can hide the balance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccountCard(
            imagePath: 'assets/images/accent_image_2.png',
            cardType: 'Deposit',
            accountNumber: '**** 7781',
            expiry: '12/34',
            balance: 'hidden',
            showBalance: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('hidden'), findsNothing);
    expect(find.text('Deposit'), findsOneWidget);
  });
}
