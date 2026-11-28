import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

void main() {
  test('screen inset is 32 horizontal and 16 vertical', () {
    expect(screenPadding.left, 32);
    expect(screenPadding.right, 32);
    expect(screenPadding.top, 16);
    expect(screenPadding.bottom, 16);
  });

  test('bottom bar keeps two 32px side margins', () {
    expect(screenSideMargin, 32);
    expect(bottomNavWidth(400), 336);
    expect(bottomNavWidth(360), 296);
  });

  test('branch top-bar clearance plus the shared inset is 112', () {
    expect(shellTopBarExtraTop + screenPadding.top, 112);
  });
}
