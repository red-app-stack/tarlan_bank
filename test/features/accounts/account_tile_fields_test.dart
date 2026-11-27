import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/features/accounts/data/account_model.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';

void main() {
  test('account artwork and balance visibility survive a map round-trip', () {
    final account = Account(
      number: '1234567890123456',
      ownerId: 'uid1',
      type: AccountType.current,
      currency: 'KZT',
      balance: 1000,
      status: AccountStatus.active,
      imagePath: 'assets/images/accent_image_2.png',
      hideBalance: true,
    );

    final map = account.toMap();
    expect(map['imagePath'], 'assets/images/accent_image_2.png');
    expect(map['hideBalance'], true);

    final back = Account.fromMap(account.number, map);
    expect(back.imagePath, 'assets/images/accent_image_2.png');
    expect(back.hideBalance, true);
  });

  test('legacy account maps default to fallback image and visible balance', () {
    final account = Account.fromMap('1234567890123456', {
      'ownerId': 'uid1',
      'type': 'current',
      'currency': 'KZT',
      'balance': 0,
      'status': 'active',
    });
    expect(account.imagePath, isNull);
    expect(account.hideBalance, false);
  });

  test('tile formatters mask and shorten for narrow cards', () {
    expect(maskLast4('1234567890123456'), '**** 3456');
    expect(formatCardExpiry(4, 2031), '04/31');
  });
}
