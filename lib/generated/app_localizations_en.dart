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

  @override
  String get openApp => 'Open app';

  @override
  String get navPayments => 'Payments';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navMenu => 'Menu';

  @override
  String get searchHint => 'Search…';

  @override
  String get transferByAccount => 'By account number';

  @override
  String get conversion => 'Conversion';

  @override
  String get mobileTransfer => 'Mobile transfer';

  @override
  String get qrTransfer => 'QR transfer';

  @override
  String get ownAccounts => 'Between my accounts';

  @override
  String get receipt => 'Receipt';

  @override
  String get transferHistory => 'Transfer history';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get amount => 'Amount';

  @override
  String get recipientAccountNumber => 'Recipient account number';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get recipient => 'Recipient';

  @override
  String get message => 'Message';

  @override
  String get messageHint => 'Message to recipient';

  @override
  String get scan => 'Scan';

  @override
  String get create => 'Create';

  @override
  String get createQrCode => 'Create QR code';

  @override
  String get qrHint =>
      'If you don\'t specify an amount, the sender can enter it when scanning your QR code';

  @override
  String get transferVerb => 'Transfer';

  @override
  String get errorSelectCard => 'Please select a card';

  @override
  String get errorEnterAmount => 'Please enter an amount';

  @override
  String get errorEnterAccount => 'Please enter a valid account number';

  @override
  String get errorEnterPhone => 'Please enter a phone number';

  @override
  String get recipientNotFound => 'Recipient not found';

  @override
  String get transferSuccess => 'Transfer completed successfully';

  @override
  String get transferFailed => 'Transfer failed';

  @override
  String get noAccounts => 'You have no available accounts';

  @override
  String get noTransfers => 'Your transfer history will appear here';

  @override
  String today(String date) {
    return 'Today, $date';
  }

  @override
  String get week => 'Last week';

  @override
  String get month => 'Last month';

  @override
  String get threeMonths => 'Last 3 months';

  @override
  String get customPeriod => 'Selected period';

  @override
  String get calendarPeriod => 'Pick a period in calendar';

  @override
  String get selectPeriod => 'Select period';

  @override
  String get choose => 'Choose';

  @override
  String get share => 'Share';

  @override
  String get repeat => 'Repeat';

  @override
  String get cancelTransfer => 'Cancel';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get transactionType => 'Transaction type';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get dateTime => 'Date and time';

  @override
  String get commission => 'Commission';

  @override
  String get sender => 'Sender';

  @override
  String get senderAccount => 'Sender account';

  @override
  String get unknown => 'Unknown';

  @override
  String statusCompleted(String type) {
    return '$type completed successfully';
  }

  @override
  String statusPending(String type) {
    return '$type is being processed';
  }

  @override
  String statusFailed(String type) {
    return '$type failed';
  }

  @override
  String get typeDeposit => 'Deposit';

  @override
  String get typeWithdrawal => 'Withdrawal';

  @override
  String get typePhoneTransfer => 'Phone transfer';

  @override
  String get typeQrTransfer => 'QR transfer';

  @override
  String get typeCurrencyConversion => 'Currency exchange';

  @override
  String get typeInternalTransfer => 'Internal transfer';

  @override
  String get typeCardTransfer => 'Card transfer';

  @override
  String get typeSwiftTransfer => 'SWIFT transfer';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get noTransaction => 'No transaction selected';

  @override
  String get accountCurrent => 'Current';

  @override
  String get accountDeposit => 'Deposit';

  @override
  String get accountCredit => 'Credit';

  @override
  String get auSettingsTitle => 'Settings';

  @override
  String get auSettingsThemeTitle => 'App theme';

  @override
  String get auSettingsThemeSubtitle => 'Choose light, dark, or system theme';

  @override
  String get auThemeSystem => 'System';

  @override
  String get auThemeLight => 'Light';

  @override
  String get auThemeDark => 'Dark';

  @override
  String get auSettingsQuickToggleTitle => 'Quick theme switch';

  @override
  String get auSettingsQuickToggleSubtitle =>
      'Tap to switch between light and dark';

  @override
  String get auCodeCreateTitle => 'Create an access code';

  @override
  String get auCodeRepeatTitle => 'Repeat the access code';

  @override
  String get auCodeEnterTitle => 'Enter the access code';

  @override
  String get auCodeResetButton => 'Reset access code';

  @override
  String get auCodeForgotButton => 'Forgot access code?';

  @override
  String auCodeLocked(String time) {
    return 'Too many attempts. Try again in $time';
  }

  @override
  String get auBiometricAuthTitle => 'Biometric authentication';

  @override
  String get auBiometricAuthBody =>
      'Do you want to use biometric authentication?';

  @override
  String get auBiometricSignInReason => 'Use Touch ID to sign in to the app';

  @override
  String get auBiometricSignInTitle => 'Sign in to the app';

  @override
  String get auBiometricFallbackTitle => 'Biometric authentication';

  @override
  String get auBiometricNotSupported =>
      'Touch ID is not supported on this device';

  @override
  String get auBiometricUnavailable => 'Touch ID is unavailable';

  @override
  String get auWrongAccessCode => 'Incorrect access code';

  @override
  String get auMessageTitle => 'Message';

  @override
  String get auYes => 'Yes';

  @override
  String get auNo => 'No';

  @override
  String get auVerificationTitle => 'Enter confirmation code';

  @override
  String get auVerificationCodeLabel => 'Confirmation code';

  @override
  String get auVerificationCodeHint => '000000';

  @override
  String get auVerificationSendFailed => 'Failed to send the code';

  @override
  String get auVerificationCodeLengthInvalid => 'Code must be 6 digits';

  @override
  String get auVerificationInvalidCode => 'Invalid code';

  @override
  String get auVerificationCheckFailed =>
      'Failed to verify the code. Please try again';

  @override
  String get auChangePassword => 'Change password';

  @override
  String get auLinkedAccounts => 'Linked accounts';

  @override
  String get auChangeAccessCode => 'Change access code';

  @override
  String get auAuthorizationTitle => 'Authorization';

  @override
  String get auBiometricLoginDesc => 'Sign in to the app with biometrics';

  @override
  String get auScreenProtectionTitle => 'Screen recording protection';

  @override
  String get auScreenProtectionDesc => 'Screenshots and screen recording';

  @override
  String get auBiometricOperationsTitle => 'Biometric operations';

  @override
  String get auBiometricOperationsDesc => 'Confirming transfers';

  @override
  String get auDeleteAccountRequest => 'Request account deletion';

  @override
  String get auBiometricUnavailableDevice =>
      'Biometrics are not available on this device';

  @override
  String get auBiometricAuthRequired => 'Biometric confirmation required';

  @override
  String get auBiometricChangeHint => 'Changing requires authorization';

  @override
  String get auEmailConfirmationRequired => 'Email confirmation required';

  @override
  String get auConfirmationRequired => 'Confirmation required';

  @override
  String get auDeleteConfirmHint => 'Confirm account deletion.';

  @override
  String get auProfileTitle => 'Profile';

  @override
  String get auMyNotifications => 'My notifications';

  @override
  String get auNotificationsTitle => 'Notifications';

  @override
  String get auAppLanguage => 'App language';

  @override
  String get auPhoneTransfers => 'Phone transfers';

  @override
  String get auAccountOperations => 'Account operations';

  @override
  String get auNoOperations => 'No operations yet';

  @override
  String get auNoTransfers => 'No transfers yet';

  @override
  String get auNoPayments => 'No payments yet';

  @override
  String get auTrustedPhone => 'Your trusted number';

  @override
  String get auSecurityTip =>
      'Do not follow unverified links and do not enter your personal data on unknown websites. Scammers may use fake links and pages to steal information. Always check the source of messages and make sure the website address belongs to your bank. Remember: bank employees will never ask for your password or an SMS code.';

  @override
  String get auTxDeposit => 'Deposit';

  @override
  String get auTxWithdrawal => 'Withdrawal';

  @override
  String get auTxPhoneTransfer => 'Phone transfer';

  @override
  String get auTxQrTransfer => 'QR transfer';

  @override
  String get auTxCurrencyConversion => 'Currency exchange';

  @override
  String get auTxInternalTransfer => 'Internal transfer';

  @override
  String get auTxCardTransfer => 'Card transfer';

  @override
  String get auTxSwiftTransfer => 'SWIFT transfer';

  @override
  String get auTxTransfer => 'Transfer';

  @override
  String get history => 'History';

  @override
  String get popular => 'Popular';

  @override
  String get favorites => 'Favorites';

  @override
  String get zhambylRegion => 'Zhambyl region';

  @override
  String get serviceMobile => 'Mobile';

  @override
  String get serviceInternet => 'Internet';

  @override
  String get serviceTransport => 'Transport';

  @override
  String get serviceUtilities => 'Utilities';

  @override
  String get openNewCard => 'Open a new card';

  @override
  String get creditCash => 'Get a cash loan';

  @override
  String get creditCashSubtitle => 'Online up to 7,000,000 KZT';

  @override
  String get openDepositSubtitle => 'At favorable terms';

  @override
  String get multiCurrency => 'Multi-currency';

  @override
  String get emptyAccounts => 'No accounts yet';

  @override
  String get transferByPhone => 'By phone number';

  @override
  String get transferByPhoneDesc => 'For individuals and businesses';

  @override
  String get transferBetweenOwn => 'Between my accounts';

  @override
  String get transferBetweenOwnDesc => 'Cards, accounts, deposits';

  @override
  String get transferKz => 'Within Kazakhstan';

  @override
  String get transferKzDesc => 'To a card or account number';

  @override
  String get transferInternational => 'International transfers';

  @override
  String get transferInternationalDesc => 'Anywhere in the world';

  @override
  String get conversionDesc => 'Currency exchange';

  @override
  String get bankQr => 'Bank QR';

  @override
  String get bankQrDesc => 'Create a QR to receive money';

  @override
  String get saved => 'Saved';

  @override
  String get cardDetails => 'Card details';

  @override
  String get cardDetailsEmpty => 'Card data is not available';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get pendingAmount => 'Pending: 0.00 KZT';

  @override
  String get topUp => 'Top up';

  @override
  String get transfer => 'Transfer';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get statement => 'Statement';

  @override
  String get incomeExpenses => 'Income and expenses';

  @override
  String get requisites => 'Bank details';

  @override
  String get accountNumbers => 'Account numbers';

  @override
  String get closeCard => 'Close card';

  @override
  String get renameCard => 'Rename card';

  @override
  String get manageSubscriptions => 'Manage subscriptions';

  @override
  String get orderCard => 'Order a card';

  @override
  String get setLimits => 'Set limits';

  @override
  String get getCertificate => 'Get a certificate';

  @override
  String get blocks => 'Blocks';

  @override
  String get cardSettings => 'Card settings';

  @override
  String get portfolioTenge => 'Portfolio in tenge';

  @override
  String get statistics => 'Statistics';

  @override
  String get operations => 'Operations';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get paymentHistoryEmpty => 'Your payment history will appear here';

  @override
  String get periodWeek => 'Last week';

  @override
  String get periodMonth => 'Last month';

  @override
  String get period3Months => 'Last 3 months';

  @override
  String get periodCustom => 'Selected period';

  @override
  String get periodCalendar => 'Pick a period in calendar';

  @override
  String get choosePeriod => 'Choose a period';

  @override
  String get categoryThisWeek => 'This week';

  @override
  String get categoryThisMonth => 'This month';

  @override
  String get categoryEarlier => 'Earlier';

  @override
  String get txDeposit => 'Deposit';

  @override
  String get txWithdrawal => 'Withdrawal';

  @override
  String get txPhoneTransfer => 'Phone transfer';

  @override
  String get txQrTransfer => 'QR transfer';

  @override
  String get txConversion => 'Currency exchange';

  @override
  String get txInternalTransfer => 'Internal transfer';

  @override
  String get txCardTransfer => 'Card transfer';

  @override
  String get txSwiftTransfer => 'SWIFT transfer';

  @override
  String get txPayment => 'Payment';

  @override
  String get txOther => 'Transfer';

  @override
  String get convertTitle => 'Currency conversion';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get linkedAccountsTitle => 'Linked accounts';

  @override
  String get featurePlaceholderBody => 'This screen is not available yet.';

  @override
  String get recipientLookupLimited => 'Recipient not found; try again later';

  @override
  String get transferNetworkError => 'Network unavailable. Try again.';

  @override
  String get transferServerError => 'Server error. Try again later.';

  @override
  String get transferAuthError => 'Session expired. Please sign in again.';

  @override
  String get transferValidationError =>
      'Check the amount and recipient, then try again.';

  @override
  String get transferInsufficientFunds => 'Insufficient balance.';

  @override
  String get transferRateUnavailable =>
      'Exchange rate unavailable. Try again later.';

  @override
  String get transferAccountInactive => 'Account is not active.';

  @override
  String get transferOverpayment => 'Repayment exceeds the outstanding debt.';

  @override
  String get convertedAmount => 'Converted amount';

  @override
  String get exchangeRate => 'Exchange rate';

  @override
  String get transferTooManyRequests =>
      'Too many attempts. Try again in a minute.';

  @override
  String get bioSetupTitle => 'Biometric authentication is now available';

  @override
  String get bioSetupBody =>
      'Sign in faster with your phone\'s biometric credentials instead of typing your access code.';

  @override
  String get bioSetupEnable => 'Enable biometric login';

  @override
  String get bioSetupSkip => 'Skip for now';

  @override
  String get bioSetupDoneTitle => 'Biometric authentication is now set up';

  @override
  String get bioSetupDoneBody => 'Turn it off anytime from Settings.';

  @override
  String get bioSetupContinue => 'Continue';

  @override
  String get bioSetupReason =>
      'Confirm your fingerprint to enable biometric login';

  @override
  String get bioSetupUnavailable =>
      'Biometric authentication is not available on this device';

  @override
  String get bioSetupFailed =>
      'Could not enable biometric login. Please try again.';

  @override
  String get faceTitle => 'Face verification';

  @override
  String get faceIntroTitle => 'Verify your identity';

  @override
  String get faceIntroBody =>
      'We check that a real person is using this account. It takes about 10 seconds. Video is analysed on your device and is not recorded or stored.';

  @override
  String get faceTipCenter => 'Center your face in the oval';

  @override
  String get faceTipLight => 'Stand in good, even lighting';

  @override
  String get faceTipObstruct =>
      'Remove glasses, mask, hat or anything covering your face';

  @override
  String get faceTipStill => 'Hold still when asked';

  @override
  String get faceStart => 'Start scan';

  @override
  String get faceUsePin => 'Use access code instead';

  @override
  String get faceContactSupport => 'Contact support';

  @override
  String get faceHintNoFace => 'Position your face in the oval';

  @override
  String get faceHintMultiple => 'Only one face should be visible';

  @override
  String get faceHintCloser => 'Move a little closer';

  @override
  String get faceHintFarther => 'Move a little farther';

  @override
  String get faceHintCenter => 'Center your face';

  @override
  String get faceHintHold => 'Hold still…';

  @override
  String get faceChallengeBlink => 'Blink slowly';

  @override
  String get faceChallengeSmile => 'Smile';

  @override
  String get faceChallengeTurn => 'Turn your head to one side, then back';

  @override
  String get faceSuccessTitle => 'Verified';

  @override
  String get faceSuccessBody => 'Your identity check is complete.';

  @override
  String get faceErrPermissionTitle => 'Camera access is off';

  @override
  String get faceErrPermissionBody =>
      'Allow camera access to verify your face.';

  @override
  String get faceOpenSettings => 'Open settings';

  @override
  String get faceErrNoCameraTitle => 'No camera found';

  @override
  String get faceErrNoCameraBody =>
      'This device has no usable front camera. Use your access code or contact support.';

  @override
  String get faceErrTimeoutTitle => 'Scan timed out';

  @override
  String get faceErrTimeoutBody =>
      'The check could not be completed in time. Try again in better light.';

  @override
  String get faceErrGenericTitle => 'Scan failed';

  @override
  String get faceErrGenericBody =>
      'Something went wrong with the camera. Please try again.';

  @override
  String get faceSupportSent =>
      'Request sent. Support will review it. Until then you can use the app with limited access.';

  @override
  String get faceSupportFailed =>
      'Could not send the request. Check your connection and try again.';

  @override
  String get auDeleteReauthNeeded =>
      'Please sign in again, then retry account deletion.';

  @override
  String get auDeleteFailed =>
      'Could not delete the account. Please try again.';

  @override
  String get reauthTitle => 'Confirm it\'s you';

  @override
  String get reauthBody =>
      'For your security, sign in again to finish this action.';

  @override
  String get reauthConfirm => 'Confirm';

  @override
  String get reauthInvalidPassword => 'Incorrect password. Please try again.';

  @override
  String get reauthGoogle => 'Continue with Google';

  @override
  String get reauthNoMethod =>
      'This sign-in method cannot be confirmed here. Please sign in again from the start.';

  @override
  String get language => 'Language';

  @override
  String get langSys => 'System';

  @override
  String get callFailed => 'Could not open the dialer.';

  @override
  String get chatBotName => 'Tarlan Assistant';

  @override
  String get chatBotSubtitle => 'Banking support · 24/7';

  @override
  String get chatBotThinking => 'Thinking…';

  @override
  String get chatClearConversation => 'Clear conversation';

  @override
  String get chatGreeting =>
      'Hi! I\'m Tarlan\'s AI assistant. Ask me about cards, payments, deposits or loans.';

  @override
  String get chatErrorResponse =>
      'Sorry, I couldn\'t respond. Please try again.';

  @override
  String get chatEmptyTitle => 'Ask Tarlan AI';

  @override
  String get chatEmptySubtitle =>
      'Cards, payments, deposits and loans —\nI\'m here to help.';

  @override
  String get chatInputHint => 'Ask about banking…';

  @override
  String get chatInputHintThinking => 'Waiting for a reply…';

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatCopied => 'Copied to clipboard';
}
