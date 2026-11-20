import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';
import 'package:tarlan_bank/features/transactions/data/transfer_validation.dart';

Account _account({
  String number = '1111222233334444',
  String ownerId = 'uid1',
  AccountType type = AccountType.current,
  String currency = 'KZT',
  double balance = 1000,
  AccountStatus status = AccountStatus.active,
}) =>
    Account(
      number: number,
      ownerId: ownerId,
      type: type,
      currency: currency,
      balance: balance,
      status: status,
      creditTerms: type == AccountType.credit
          ? const CreditTerms(
              creditLimit: 100000, annualRate: 0.18, termMonths: 24)
          : null,
      depositTerms: type == AccountType.deposit
          ? DepositTerms(
              annualRate: 0.14,
              termMonths: 12,
              maturityAt: DateTime.utc(2027, 1, 1))
          : null,
    );

void main() {
  final sender = _account();
  final recipient =
      _account(number: '5555666677778888', ownerId: 'uid2', balance: 200);

  group('planTransfer — happy paths', () {
    test('phone transfer moves exact amounts, 2dp rounded', () {
      final plan = planTransfer(
        type: TransactionType.phoneTransfer,
        amount: 100.555,
        currency: 'KZT',
        from: sender,
        to: recipient,
      );
      expect(plan.fromBalance, 899.44); // 1000 - 100.56
      expect(plan.toBalance, 300.56); // 200 + 100.56
    });

    test('full balance is allowed (sender lands exactly on zero)', () {
      final plan = planTransfer(
        type: TransactionType.phoneTransfer,
        amount: 1000,
        currency: 'KZT',
        from: sender,
        to: recipient,
      );
      expect(plan.fromBalance, 0);
    });

    test('internal transfer between own accounts', () {
      final own = _account(number: '5555666677778888', balance: 0);
      final plan = planTransfer(
        type: TransactionType.internalTransfer,
        amount: 500,
        currency: 'KZT',
        from: sender,
        to: own,
      );
      expect(plan.fromBalance, 500);
      expect(plan.toBalance, 500);
    });

    test('deposit: recipient only, balance grows', () {
      final plan = planTransfer(
        type: TransactionType.deposit,
        amount: 250,
        currency: 'KZT',
        to: recipient,
      );
      expect(plan.fromBalance, isNull);
      expect(plan.toBalance, 450);
    });

    test('withdrawal: sender only, balance shrinks', () {
      final plan = planTransfer(
        type: TransactionType.withdrawal,
        amount: 250,
        currency: 'KZT',
        from: sender,
      );
      expect(plan.fromBalance, 750);
      expect(plan.toBalance, isNull);
    });

    test('current -> credit is a repayment: BOTH balances decrease', () {
      final credit = _account(
          number: '9999888877776666', type: AccountType.credit, balance: 30000);
      final plan = planTransfer(
        type: TransactionType.internalTransfer,
        amount: 1000,
        currency: 'KZT',
        from: sender,
        to: credit,
      );
      expect(plan.fromBalance, 0);
      expect(plan.toBalance, 29000); // debt reduced
    });

    test('repayment may clear the debt exactly to zero', () {
      final credit = _account(
          number: '9999888877776666', type: AccountType.credit, balance: 1000);
      final plan = planTransfer(
        type: TransactionType.internalTransfer,
        amount: 1000,
        currency: 'KZT',
        from: sender,
        to: credit,
      );
      expect(plan.toBalance, 0);
    });
  });

  group('planTransfer — rejections', () {
    test('insufficient balance', () {
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 1000.01,
            currency: 'KZT',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()
            .having((f) => f.message, 'message', 'Insufficient balance')),
      );
    });

    test('zero / negative / non-finite amounts', () {
      for (final bad in [0.0, -5.0, double.nan, double.infinity]) {
        expect(
          () => planTransfer(
              type: TransactionType.phoneTransfer,
              amount: bad,
              currency: 'KZT',
              from: sender,
              to: recipient),
          throwsA(isA<ValidationFailure>()),
          reason: 'amount=$bad',
        );
      }
    });

    test('sub-cent amount rounds to zero and is rejected', () {
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 0.001,
            currency: 'KZT',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('unsupported currency', () {
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 1,
            currency: 'RUB',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('currency mismatch on either party', () {
      final usd = _account(number: '5555666677778888', currency: 'USD');
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 1,
            currency: 'KZT',
            from: sender,
            to: usd),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 1,
            currency: 'USD',
            from: sender,
            to: usd),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('credit account is NEVER a source', () {
      final credit = _account(
          number: '9999888877776666', type: AccountType.credit, balance: 30000);
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 1,
            currency: 'KZT',
            from: credit,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('closed / inactive accounts rejected on either side', () {
      for (final status in [AccountStatus.closed, AccountStatus.inactive]) {
        expect(
          () => planTransfer(
              type: TransactionType.phoneTransfer,
              amount: 1,
              currency: 'KZT',
              from: _account(status: status),
              to: recipient),
          throwsA(isA<ValidationFailure>()),
          reason: 'sender $status',
        );
        expect(
          () => planTransfer(
              type: TransactionType.phoneTransfer,
              amount: 1,
              currency: 'KZT',
              from: sender,
              to: _account(
                  number: '5555666677778888', ownerId: 'uid2', status: status)),
          throwsA(isA<ValidationFailure>()),
          reason: 'recipient $status',
        );
      }
    });

    test('self-transfer rejected', () {
      expect(
        () => planTransfer(
            type: TransactionType.internalTransfer,
            amount: 1,
            currency: 'KZT',
            from: sender,
            to: sender),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('internal transfer across owners rejected', () {
      expect(
        () => planTransfer(
            type: TransactionType.internalTransfer,
            amount: 1,
            currency: 'KZT',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('repayment above outstanding debt rejected', () {
      final credit = _account(
          number: '9999888877776666', type: AccountType.credit, balance: 50);
      expect(
        () => planTransfer(
            type: TransactionType.internalTransfer,
            amount: 100,
            currency: 'KZT',
            from: sender,
            to: credit),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('wrong party shape per type', () {
      // deposit with a sender
      expect(
        () => planTransfer(
            type: TransactionType.deposit,
            amount: 1,
            currency: 'KZT',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
      // withdrawal with a recipient
      expect(
        () => planTransfer(
            type: TransactionType.withdrawal,
            amount: 1,
            currency: 'KZT',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
      // transfer missing a party
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer,
            amount: 1,
            currency: 'KZT',
            from: sender),
        throwsA(isA<ValidationFailure>()),
      );
      // no parties at all
      expect(
        () => planTransfer(
            type: TransactionType.phoneTransfer, amount: 1, currency: 'KZT'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('currency conversion deferred until the exchange seam lands', () {
      expect(
        () => planTransfer(
            type: TransactionType.currencyConversion,
            amount: 1,
            currency: 'KZT',
            from: sender,
            to: recipient),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('roundMoney', () {
    test('rounds half away from zero at 2dp', () {
      expect(roundMoney(100.555), 100.56);
      expect(roundMoney(0.1 + 0.2), 0.3);
      expect(roundMoney(999.999), 1000.0);
    });
  });
}
