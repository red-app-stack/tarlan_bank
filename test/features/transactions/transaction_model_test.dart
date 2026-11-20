import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';

void main() {
  group('BankTransaction — map round-trip', () {
    test('transfer keeps both parties and owners', () {
      final created = DateTime.utc(2026, 11, 20, 9, 30);
      final t = BankTransaction(
        id: 'tx-uuid-1',
        fromAccountId: '1111222233334444',
        toAccountId: '5555666677778888',
        fromOwnerId: 'uid1',
        toOwnerId: 'uid2',
        amount: 1500.50,
        currency: 'KZT',
        type: TransactionType.phoneTransfer,
        status: TransactionStatus.completed,
        createdAt: created,
        message: 'за кофе',
      );
      final map = t.toMap();
      expect(map['type'], 'phone_transfer'); // exact rules wire string
      expect(map['createdAt'], isA<Timestamp>());
      final back = BankTransaction.fromMap(t.id, map);
      expect(back.fromAccountId, t.fromAccountId);
      expect(back.toAccountId, t.toAccountId);
      expect(back.fromOwnerId, 'uid1');
      expect(back.toOwnerId, 'uid2');
      expect(back.amount, 1500.50);
      expect(back.type, TransactionType.phoneTransfer);
      expect(back.status, TransactionStatus.completed);
      expect(back.createdAt!.toUtc(), created);
      expect(back.message, 'за кофе');
    });

    test('deposit has no sender; withdrawal no recipient', () {
      final deposit = BankTransaction(
        id: 'tx-2',
        toAccountId: '1111222233334444',
        toOwnerId: 'uid1',
        amount: 100,
        currency: 'KZT',
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
      );
      final dMap = deposit.toMap();
      expect(dMap.containsKey('fromAccountId'), false);
      expect(dMap.containsKey('fromOwnerId'), false);
      final dBack = BankTransaction.fromMap('tx-2', dMap);
      expect(dBack.fromAccountId, isNull);
      expect(dBack.toAccountId, '1111222233334444');

      final withdrawal = BankTransaction(
        id: 'tx-3',
        fromAccountId: '1111222233334444',
        fromOwnerId: 'uid1',
        amount: 100,
        currency: 'KZT',
        type: TransactionType.withdrawal,
        status: TransactionStatus.completed,
      );
      final wBack = BankTransaction.fromMap('tx-3', withdrawal.toMap());
      expect(wBack.toAccountId, isNull);
      expect(wBack.fromAccountId, '1111222233334444');
    });

    test('pending serverTimestamp tolerated (createdAt null)', () {
      final t = BankTransaction(
        id: 'tx-4',
        fromAccountId: '1111222233334444',
        toAccountId: '5555666677778888',
        fromOwnerId: 'uid1',
        toOwnerId: 'uid1',
        amount: 1,
        currency: 'USD',
        type: TransactionType.internalTransfer,
        status: TransactionStatus.completed,
      );
      expect(t.toMap().containsKey('createdAt'), false);
      expect(t.formattedCreatedAt, '');
      expect(BankTransaction.fromMap('tx-4', t.toMap()).createdAt, isNull);
    });

    test('empty message is omitted from the map', () {
      final t = BankTransaction(
        id: 'tx-5',
        toAccountId: '1111222233334444',
        toOwnerId: 'uid1',
        amount: 1,
        currency: 'KZT',
        type: TransactionType.deposit,
        status: TransactionStatus.completed,
        message: '',
      );
      expect(t.toMap().containsKey('message'), false);
    });
  });

  group('TransactionType wire names', () {
    test('every enum value round-trips through its rules string', () {
      for (final type in TransactionType.values) {
        expect(TransactionType.fromWire(type.wireName), type);
      }
    });
    test('unknown wire string throws ValidationFailure', () {
      expect(() => TransactionType.fromWire('refund'),
          throwsA(isA<ValidationFailure>()));
    });
  });
}
