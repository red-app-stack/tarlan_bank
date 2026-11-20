// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tarlan Bank';

  @override
  String get labelEnglish => 'English';

  @override
  String get labelRussian => 'Russian';

  @override
  String get labelKazakh => 'Kazakh';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get later => 'Later';

  @override
  String get loading => 'Loading…';

  @override
  String get orDivider => 'or';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get registerTitle => 'Create account';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameInvalid => 'Enter your first and last name';

  @override
  String get phone => 'Phone';

  @override
  String get phoneInvalid => 'Use format +7 701 234-56-78';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get password => 'Password';

  @override
  String get passwordRegister => 'Choose a password';

  @override
  String get passwordRequired => 'Enter a password';

  @override
  String get confirmPassword => 'Repeat password';

  @override
  String get passwordsMismatch => 'Passwords do not match';

  @override
  String get passwordStrong => 'Password is strong enough';

  @override
  String get passwordMinLength => 'At least 8 characters';

  @override
  String get passwordDigit => 'Needs at least one digit';

  @override
  String get passwordLetter => 'Needs at least one letter';

  @override
  String get passwordSpecial => 'Needs a special character (!@#\$%^&* etc.)';

  @override
  String get unexpectedError => 'Unexpected error. Please try again';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get continueGuest => 'Continue as guest';

  @override
  String get guestHint => 'Guest: home, menu and exchange rates';

  @override
  String get signInRequired => 'Sign in to open a product';

  @override
  String get verifyTitle => 'Verify your email';

  @override
  String verifyBody(String email) {
    return 'We sent a letter to $email. Follow the link in the email, then tap “Check”.';
  }

  @override
  String get verifyCheck => 'Check';

  @override
  String get verifyResend => 'Resend email';

  @override
  String verifyResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get verifyNotConfirmed =>
      'Not confirmed yet. Follow the link in the email';

  @override
  String get verifyLater => 'Later';

  @override
  String get verifySignOut => 'Sign out';

  @override
  String get home => 'Home';

  @override
  String get cards => 'Cards';

  @override
  String get deposits => 'Deposits';

  @override
  String get credits => 'Credits';

  @override
  String get installment => 'Installment';

  @override
  String get investments => 'Investments';

  @override
  String get exchangeRates => 'Exchange rates';

  @override
  String get menu => 'Menu';

  @override
  String get menuGuest => 'Menu (guest)';

  @override
  String get securitySettings => 'Security settings';

  @override
  String get products => 'Products';

  @override
  String get bankSection => 'Bank';

  @override
  String get atm => 'ATMs';

  @override
  String get branches => 'Branches';

  @override
  String get callBank => 'Call the bank';

  @override
  String get supportTickets => 'My support requests';

  @override
  String get logout => 'Sign out';

  @override
  String get createCard => 'card';

  @override
  String get createDeposit => 'deposit';

  @override
  String get createCredit => 'credit';

  @override
  String get createInstallment => 'installment';

  @override
  String get currency => 'Currency';

  @override
  String interestRate(String rate) {
    return '$rate%';
  }

  @override
  String get personalInfo => 'Personal details';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get financialInfo => 'Financial details';

  @override
  String get monthlyIncome => 'Monthly income';

  @override
  String get additionalIncome => 'Additional income';

  @override
  String get documents => 'Documents';

  @override
  String get docType => 'Document type';

  @override
  String get docNumber => 'Document number';

  @override
  String get docExpiry => 'Valid until';

  @override
  String get notUsCitizen => 'I am not a US citizen / taxpayer';

  @override
  String openProduct(String product) {
    return 'Open $product';
  }

  @override
  String productOpened(String product) {
    return '$product opened';
  }

  @override
  String failedOpen(String product) {
    return 'Failed to open $product';
  }

  @override
  String get docTypeIdentity => 'ID card of Kazakhstan';

  @override
  String get docTypePassportKz => 'Passport of Kazakhstan';

  @override
  String get docTypeResidence => 'Residence permit in Kazakhstan';

  @override
  String get docTypeStatelessKz => 'Stateless person certificate (KZ)';

  @override
  String get docTypeForeignPassport => 'Foreign passport';

  @override
  String get docTypeStateless => 'Stateless person certificate';

  @override
  String get docTypeForeignStateless => 'Foreign stateless person certificate';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';
}
