import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/core/config/service_urls.dart';
import 'package:tarlan_bank/core/errors/app_failure.dart';

void main() {
  test('parses config/urls strictly', () {
    final urls = ServiceUrls.fromMap({
      'bankApiUrl': 'https://tarlan.devtunnels.ms/',
      'aiApiUrl': 'https://ai.example.com',
      'updatedAt': DateTime.utc(2026, 11, 21).toIso8601String(),
    });
    expect(urls.bankApiUrl, 'https://tarlan.devtunnels.ms');
    expect(urls.aiApiUrl, 'https://ai.example.com');
  });

  test('rejects non-https bank URL', () {
    expect(
      () => ServiceUrls.fromMap({'bankApiUrl': 'http://insecure'}),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
