import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/views/shared/app_icons.dart';

void main() {
  test('shell constants resolve to the stateful asset files', () {
    expect(AppIcons.home, 'assets/icons/shell/home.svg');
    expect(AppIcons.homeActive, 'assets/icons/shell/home_active.svg');
    expect(AppIcons.qr, 'assets/icons/shell/qr.svg');
    expect(AppIcons.qrActive, 'assets/icons/shell/qr_active.svg');
    expect(AppIcons.menu, 'assets/icons/shell/menu.svg');
    expect(AppIcons.menuActive, 'assets/icons/shell/menu_active.svg');
    expect(AppIcons.search, 'assets/icons/shell/search.svg');
    expect(AppIcons.searchActive, 'assets/icons/shell/search_active.svg');
    expect(AppIcons.notifications, 'assets/icons/shell/notifications.svg');
    expect(AppIcons.avatarEmpty, 'assets/icons/shell/avatar_empty.svg');
  });

  test('new icon constants match their folder and file names', () {
    expect(AppIcons.add, 'assets/icons/button/add.svg');
    expect(AppIcons.edit, 'assets/icons/button/edit.svg');
    expect(AppIcons.selectAccount, 'assets/icons/button/select_account.svg');
    expect(AppIcons.history, 'assets/icons/button/history.svg');

    expect(AppIcons.transfers, 'assets/icons/widget/transfers.svg');
    expect(AppIcons.payments, 'assets/icons/widget/payments.svg');
    expect(AppIcons.deposits, 'assets/icons/widget/deposits.svg');
    expect(AppIcons.credits, 'assets/icons/widget/credits.svg');
    expect(AppIcons.investments, 'assets/icons/widget/investments.svg');
    expect(AppIcons.aiAgent, 'assets/icons/widget/ai_agent.svg');

    expect(AppIcons.gallery, 'assets/icons/scan/gallery.svg');
    expect(AppIcons.flashlight, 'assets/icons/scan/flashlight.svg');
    expect(AppIcons.flashlightOn, 'assets/icons/scan/flashlight_on.svg');
  });
}
