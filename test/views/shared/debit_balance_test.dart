import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/accounts/providers/accounts_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/debit_balance.dart';

Account _account({
  required String number,
  required AccountType type,
  required double balance,
  AccountStatus status = AccountStatus.active,
  String currency = 'KZT',
}) => Account(
  number: number,
  ownerId: 'u1',
  type: type,
  currency: currency,
  balance: balance,
  status: status,
);

void main() {
  test('debit total counts active current accounts only', () {
    final totals = DebitBalance.totals([
      _account(number: '1', type: AccountType.debit, balance: 1000),
      _account(number: '2', type: AccountType.debit, balance: 2500),
      _account(number: '3', type: AccountType.deposit, balance: 9000),
      _account(number: '4', type: AccountType.credit, balance: 7000),
      _account(
        number: '5',
        type: AccountType.debit,
        balance: 400,
        status: AccountStatus.closed,
      ),
    ]);
    expect(totals.amount, 3500);
    expect(totals.currency, 'KZT');

    final empty = DebitBalance.totals(const []);
    expect(empty.amount, 0);
    expect(empty.currency, 'KZT');
  });

  testWidgets('debit balance shows title and 32/36 bold total onSurface', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith(
            (ref) => Stream.value([
              _account(number: '1', type: AccountType.debit, balance: 1000),
              _account(number: '2', type: AccountType.debit, balance: 2500),
              _account(number: '3', type: AccountType.credit, balance: 7000),
            ]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DebitBalance()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cs = Theme.of(tester.element(find.byType(DebitBalance))).colorScheme;
    final title = tester.widget<Text>(find.text('Debit balance'));
    expect(title.style?.color, cs.onSurface);
    expect(title.style?.fontSize, 12);

    final amount = tester.widget<Text>(
      find.byWidgetPredicate(
        (w) => w is Text && w.data?.contains('3,500.00') == true,
      ),
    );
    expect(amount.style?.fontSize, 32);
    expect(amount.style?.height, closeTo(36 / 32, 0.001));
    expect(amount.style?.fontWeight, FontWeight.bold);
    expect(amount.style?.color, cs.onSurface);
  });
}
