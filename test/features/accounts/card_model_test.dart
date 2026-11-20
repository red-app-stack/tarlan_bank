import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/accounts/data/card_model.dart';

void main() {
  const card = BankCard(
    id: 'card-1',
    accountId: '1234567890123456',
    ownerId: 'uid1',
    last4: '3456',
    expiryMonth: 12,
    expiryYear: 2029,
    holderName: 'VLADISLAV SHAPKA',
    status: CardStatus.active,
    label: 'Virtual',
  );

  test('map round-trip preserves fields', () {
    final back = BankCard.fromMap(card.id, card.toMap());
    expect(back.accountId, card.accountId);
    expect(back.ownerId, card.ownerId);
    expect(back.last4, '3456');
    expect(back.expiryMonth, 12);
    expect(back.expiryYear, 2029);
    expect(back.holderName, card.holderName);
    expect(back.status, CardStatus.active);
    expect(back.label, 'Virtual');
  });

  test('NEVER serializes CVV or full PAN (PCI-DSS)', () {
    final map = card.toMap();
    expect(map.containsKey('cvv'), false);
    expect(map.containsKey('cvv2'), false);
    expect(map.containsKey('pan'), false);
    expect(map.containsKey('cardNumber'), false);
    expect(map.containsKey('number'), false);
    // last4 only, never the full 16 digits
    expect((map['last4'] as String).length, 4);
  });

  test('blocked card is not usable', () {
    final blocked = BankCard.fromMap(card.id, {
      ...card.toMap(),
      'status': 'blocked',
    });
    expect(blocked.isUsable, false);
    expect(card.isUsable, true);
  });
}
