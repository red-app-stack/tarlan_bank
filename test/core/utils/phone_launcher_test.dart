import 'package:flutter_test/flutter_test.dart';

import 'package:tarlan_bank/core/utils/phone_launcher.dart';

void main() {
  group('supportTelUri', () {
    test('builds a tel URI for the dummy support number', () {
      final uri = supportTelUri();
      expect(uri.scheme, 'tel');
      expect(uri.path, '+700****0000');
      expect(uri.toString(), 'tel:+700****0000');
    });

    test('accepts an explicit number', () {
      expect(supportTelUri('+77001112233').path, '+77001112233');
    });
  });
}
