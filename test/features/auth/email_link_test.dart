import 'package:flutter_test/flutter_test.dart';
import 'package:tarlan_bank/features/auth/providers/email_link_provider.dart';

void main() {
  test('only verification oobCodes are extracted from App Links', () {
    expect(
      verificationCodeFrom(
        Uri.parse(
          'https://tarlan-bank.firebaseapp.com/__/auth/links?mode=verifyEmail&oobCode=ABC123',
        ),
      ),
      'ABC123',
    );
    expect(
      verificationCodeFrom(
        Uri.parse(
          'https://tarlan-bank.firebaseapp.com/__/auth/links?oobCode=ABC123',
        ),
      ),
      'ABC123',
    );
    expect(
      verificationCodeFrom(
        Uri.parse(
          'https://tarlan-bank.firebaseapp.com/__/auth/links?mode=resetPassword&oobCode=ABC123',
        ),
      ),
      isNull,
    );
    expect(
      verificationCodeFrom(Uri.parse('https://tarlan-bank.firebaseapp.com/')),
      isNull,
    );
  });
  test('unwraps Firebase link= wrapper around the auth action URI', () {
    final nested =
        'https://tarlan-bank.firebaseapp.com/__/auth/action?apiKey=KEY&mode=verifyEmail&oobCode=XYZ789&continueUrl=https://tarlan-bank.firebaseapp.com/&lang=ru';
    final outer = Uri.parse(
      'https://tarlan-bank.firebaseapp.com/__/auth/links?link=${Uri.encodeQueryComponent(nested)}',
    );
    expect(verificationCodeFrom(outer), 'XYZ789');

    final wrongMode = Uri.parse(
      'https://tarlan-bank.firebaseapp.com/__/auth/links?link=${Uri.encodeQueryComponent(nested.replaceFirst('mode=verifyEmail', 'mode=resetPassword'))}',
    );
    expect(verificationCodeFrom(wrongMode), isNull);
  });
}
