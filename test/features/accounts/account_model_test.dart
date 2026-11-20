import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';

void main() {
  final maturity = DateTime.utc(2027, 6, 1);

  group('Account — deposit', () {
    final account = Account(
      number: '1234567890123456',
      ownerId: 'uid1',
      type: AccountType.deposit,
      currency: 'KZT',
      balance: 100000,
      status: AccountStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      depositTerms: DepositTerms(
        annualRate: 0.14,
        termMonths: 12,
        maturityAt: maturity,
        autoRenew: true,
      ),
    );

    test('map round-trip preserves terms', () {
      final back = Account.fromMap(account.number, account.toMap());
      expect(back.type, AccountType.deposit);
      expect(back.balance, 100000);
      expect(back.depositTerms!.annualRate, 0.14);
      expect(back.depositTerms!.termMonths, 12);
      expect(back.depositTerms!.maturityAt.toUtc(), maturity);
      expect(back.depositTerms!.autoRenew, true);
      expect(back.creditTerms, isNull);
    });

    test('deposit has funds, no credit line; UI restricts sources to current',
        () {
      // isSpendable == transfer-source eligible. Deposits are funds but the
      // app restricts transfers to current accounts at the UI layer; the
      // model flag only excludes credit + non-active.
      expect(account.isSpendable, true);
      expect(account.availableCredit, isNull);
    });
  });

  group('Account — credit', () {
    final credit = Account(
      number: '9999888877776666',
      ownerId: 'uid1',
      type: AccountType.credit,
      currency: 'KZT',
      balance: 30000, // outstanding debt
      status: AccountStatus.active,
      creditTerms: const CreditTerms(
        creditLimit: 100000,
        annualRate: 0.18,
        termMonths: 24,
      ),
    );

    test('availableCredit = limit - debt', () {
      expect(credit.availableCredit, 70000);
    });

    test('credit is NEVER a transfer source', () {
      expect(credit.isSpendable, false);
    });

    test('map round-trip preserves terms', () {
      final back = Account.fromMap(credit.number, credit.toMap());
      expect(back.type, AccountType.credit);
      expect(back.creditTerms!.creditLimit, 100000);
      expect(back.creditTerms!.annualRate, 0.18);
      expect(back.creditTerms!.nextPaymentAt, isNull);
      expect(back.depositTerms, isNull);
    });

    test('fully drawn credit has zero available', () {
      final drawn = Account.fromMap(credit.number, {
        ...credit.toMap(),
        'balance': 100000.0,
      });
      expect(drawn.availableCredit, 0);
    });
  });

  group('Account — current', () {
    test('no terms, spendable when active', () {
      final current = Account(
        number: '1111222233334444',
        ownerId: 'uid1',
        type: AccountType.current,
        currency: 'KZT',
        balance: 500,
        status: AccountStatus.active,
      );
      expect(current.isSpendable, true);
      expect(current.toMap().containsKey('terms'), false);
      final back = Account.fromMap(current.number, current.toMap());
      expect(back.type, AccountType.current);
      expect(back.createdAt, isNull); // pending serverTimestamp tolerated
    });

    test('closed account is not spendable', () {
      final closed = Account(
        number: '1111222233334444',
        ownerId: 'uid1',
        type: AccountType.current,
        currency: 'KZT',
        balance: 500,
        status: AccountStatus.closed,
      );
      expect(closed.isSpendable, false);
    });

    test('timestamp fields survive round-trip', () {
      final created = DateTime.utc(2026, 5, 5, 12, 30);
      final a = Account(
        number: '1111222233334444',
        ownerId: 'uid1',
        type: AccountType.current,
        currency: 'USD',
        balance: 1,
        status: AccountStatus.active,
        createdAt: created,
      );
      final map = a.toMap();
      expect(map['createdAt'], isA<Timestamp>());
      expect(Account.fromMap(a.number, map).createdAt!.toUtc(), created);
    });
  });
}
