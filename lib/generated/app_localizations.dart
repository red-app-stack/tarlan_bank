import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Tarlan Bank'**
  String get appName;

  /// No description provided for @labelEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get labelEnglish;

  /// No description provided for @labelRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get labelRussian;

  /// No description provided for @labelKazakh.
  ///
  /// In en, this message translates to:
  /// **'Kazakh'**
  String get labelKazakh;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your first and last name'**
  String get fullNameInvalid;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use format +7 701 234-56-78'**
  String get phoneInvalid;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRegister.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get passwordRegister;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get passwordRequired;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get confirmPassword;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMismatch;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Password is strong enough'**
  String get passwordStrong;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordDigit.
  ///
  /// In en, this message translates to:
  /// **'Needs at least one digit'**
  String get passwordDigit;

  /// No description provided for @passwordLetter.
  ///
  /// In en, this message translates to:
  /// **'Needs at least one letter'**
  String get passwordLetter;

  /// No description provided for @passwordSpecial.
  ///
  /// In en, this message translates to:
  /// **'Needs a special character (!@#\$%^&* etc.)'**
  String get passwordSpecial;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error. Please try again'**
  String get unexpectedError;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccount;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInGoogle;

  /// No description provided for @continueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueGuest;

  /// No description provided for @guestHint.
  ///
  /// In en, this message translates to:
  /// **'Guest: home, menu and exchange rates'**
  String get guestHint;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to open a product'**
  String get signInRequired;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a letter to {email}. Follow the link in the email, then tap “Check”.'**
  String verifyBody(String email);

  /// No description provided for @verifyCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get verifyCheck;

  /// No description provided for @verifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyResend;

  /// No description provided for @verifyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} s'**
  String verifyResendIn(int seconds);

  /// No description provided for @verifyNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet. Follow the link in the email'**
  String get verifyNotConfirmed;

  /// No description provided for @verifyLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get verifyLater;

  /// No description provided for @verifySignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get verifySignOut;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @deposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get deposits;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @installment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get installment;

  /// No description provided for @investments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get investments;

  /// No description provided for @exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get exchangeRates;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @menuGuest.
  ///
  /// In en, this message translates to:
  /// **'Menu (guest)'**
  String get menuGuest;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security settings'**
  String get securitySettings;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @bankSection.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankSection;

  /// No description provided for @atm.
  ///
  /// In en, this message translates to:
  /// **'ATMs'**
  String get atm;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @callBank.
  ///
  /// In en, this message translates to:
  /// **'Call the bank'**
  String get callBank;

  /// No description provided for @supportTickets.
  ///
  /// In en, this message translates to:
  /// **'My support requests'**
  String get supportTickets;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @createCard.
  ///
  /// In en, this message translates to:
  /// **'card'**
  String get createCard;

  /// No description provided for @createDeposit.
  ///
  /// In en, this message translates to:
  /// **'deposit'**
  String get createDeposit;

  /// No description provided for @createCredit.
  ///
  /// In en, this message translates to:
  /// **'credit'**
  String get createCredit;

  /// No description provided for @createInstallment.
  ///
  /// In en, this message translates to:
  /// **'installment'**
  String get createInstallment;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String interestRate(String rate);

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalInfo;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @financialInfo.
  ///
  /// In en, this message translates to:
  /// **'Financial details'**
  String get financialInfo;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get monthlyIncome;

  /// No description provided for @additionalIncome.
  ///
  /// In en, this message translates to:
  /// **'Additional income'**
  String get additionalIncome;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @docType.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get docType;

  /// No description provided for @docNumber.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get docNumber;

  /// No description provided for @docExpiry.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get docExpiry;

  /// No description provided for @notUsCitizen.
  ///
  /// In en, this message translates to:
  /// **'I am not a US citizen / taxpayer'**
  String get notUsCitizen;

  /// No description provided for @openProduct.
  ///
  /// In en, this message translates to:
  /// **'Open {product}'**
  String openProduct(String product);

  /// No description provided for @productOpened.
  ///
  /// In en, this message translates to:
  /// **'{product} opened'**
  String productOpened(String product);

  /// No description provided for @failedOpen.
  ///
  /// In en, this message translates to:
  /// **'Failed to open {product}'**
  String failedOpen(String product);

  /// No description provided for @docTypeIdentity.
  ///
  /// In en, this message translates to:
  /// **'ID card of Kazakhstan'**
  String get docTypeIdentity;

  /// No description provided for @docTypePassportKz.
  ///
  /// In en, this message translates to:
  /// **'Passport of Kazakhstan'**
  String get docTypePassportKz;

  /// No description provided for @docTypeResidence.
  ///
  /// In en, this message translates to:
  /// **'Residence permit in Kazakhstan'**
  String get docTypeResidence;

  /// No description provided for @docTypeStatelessKz.
  ///
  /// In en, this message translates to:
  /// **'Stateless person certificate (KZ)'**
  String get docTypeStatelessKz;

  /// No description provided for @docTypeForeignPassport.
  ///
  /// In en, this message translates to:
  /// **'Foreign passport'**
  String get docTypeForeignPassport;

  /// No description provided for @docTypeStateless.
  ///
  /// In en, this message translates to:
  /// **'Stateless person certificate'**
  String get docTypeStateless;

  /// No description provided for @docTypeForeignStateless.
  ///
  /// In en, this message translates to:
  /// **'Foreign stateless person certificate'**
  String get docTypeForeignStateless;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get openApp;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get navTransfers;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @transferByAccount.
  ///
  /// In en, this message translates to:
  /// **'By account number'**
  String get transferByAccount;

  /// No description provided for @conversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get conversion;

  /// No description provided for @mobileTransfer.
  ///
  /// In en, this message translates to:
  /// **'Mobile transfer'**
  String get mobileTransfer;

  /// No description provided for @qrTransfer.
  ///
  /// In en, this message translates to:
  /// **'QR transfer'**
  String get qrTransfer;

  /// No description provided for @ownAccounts.
  ///
  /// In en, this message translates to:
  /// **'Between my accounts'**
  String get ownAccounts;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @transferHistory.
  ///
  /// In en, this message translates to:
  /// **'Transfer history'**
  String get transferHistory;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @recipientAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Recipient account number'**
  String get recipientAccountNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message to recipient'**
  String get messageHint;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createQrCode.
  ///
  /// In en, this message translates to:
  /// **'Create QR code'**
  String get createQrCode;

  /// No description provided for @qrHint.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t specify an amount, the sender can enter it when scanning your QR code'**
  String get qrHint;

  /// No description provided for @transferVerb.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferVerb;

  /// No description provided for @errorSelectCard.
  ///
  /// In en, this message translates to:
  /// **'Please select a card'**
  String get errorSelectCard;

  /// No description provided for @errorEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get errorEnterAmount;

  /// No description provided for @errorEnterAccount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid account number'**
  String get errorEnterAccount;

  /// No description provided for @errorEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get errorEnterPhone;

  /// No description provided for @recipientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recipient not found'**
  String get recipientNotFound;

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed successfully'**
  String get transferSuccess;

  /// No description provided for @transferFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed'**
  String get transferFailed;

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'You have no available accounts'**
  String get noAccounts;

  /// No description provided for @noTransfers.
  ///
  /// In en, this message translates to:
  /// **'Your transfer history will appear here'**
  String get noTransfers;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String today(String date);

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get month;

  /// No description provided for @threeMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get threeMonths;

  /// No description provided for @customPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get customPeriod;

  /// No description provided for @calendarPeriod.
  ///
  /// In en, this message translates to:
  /// **'Pick a period in calendar'**
  String get calendarPeriod;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get selectPeriod;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @cancelTransfer.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTransfer;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get transactionType;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateTime;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @senderAccount.
  ///
  /// In en, this message translates to:
  /// **'Sender account'**
  String get senderAccount;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'{type} completed successfully'**
  String statusCompleted(String type);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'{type} is being processed'**
  String statusPending(String type);

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'{type} failed'**
  String statusFailed(String type);

  /// No description provided for @typeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get typeDeposit;

  /// No description provided for @typeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get typeWithdrawal;

  /// No description provided for @typePhoneTransfer.
  ///
  /// In en, this message translates to:
  /// **'Phone transfer'**
  String get typePhoneTransfer;

  /// No description provided for @typeQrTransfer.
  ///
  /// In en, this message translates to:
  /// **'QR transfer'**
  String get typeQrTransfer;

  /// No description provided for @typeCurrencyConversion.
  ///
  /// In en, this message translates to:
  /// **'Currency exchange'**
  String get typeCurrencyConversion;

  /// No description provided for @typeInternalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Internal transfer'**
  String get typeInternalTransfer;

  /// No description provided for @typeCardTransfer.
  ///
  /// In en, this message translates to:
  /// **'Card transfer'**
  String get typeCardTransfer;

  /// No description provided for @typeSwiftTransfer.
  ///
  /// In en, this message translates to:
  /// **'SWIFT transfer'**
  String get typeSwiftTransfer;

  /// No description provided for @typeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get typeTransfer;

  /// No description provided for @noTransaction.
  ///
  /// In en, this message translates to:
  /// **'No transaction selected'**
  String get noTransaction;

  /// No description provided for @accountCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get accountCurrent;

  /// No description provided for @accountDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get accountDeposit;

  /// No description provided for @accountCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get accountCredit;

  /// No description provided for @auSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get auSettingsTitle;

  /// No description provided for @auSettingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get auSettingsThemeTitle;

  /// No description provided for @auSettingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or system theme'**
  String get auSettingsThemeSubtitle;

  /// No description provided for @auThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auThemeSystem;

  /// No description provided for @auThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get auThemeLight;

  /// No description provided for @auThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get auThemeDark;

  /// No description provided for @auSettingsQuickToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick theme switch'**
  String get auSettingsQuickToggleTitle;

  /// No description provided for @auSettingsQuickToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch between light and dark'**
  String get auSettingsQuickToggleSubtitle;

  /// No description provided for @auCodeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an access code'**
  String get auCodeCreateTitle;

  /// No description provided for @auCodeRepeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat the access code'**
  String get auCodeRepeatTitle;

  /// No description provided for @auCodeEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the access code'**
  String get auCodeEnterTitle;

  /// No description provided for @auCodeResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset access code'**
  String get auCodeResetButton;

  /// No description provided for @auCodeForgotButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot access code?'**
  String get auCodeForgotButton;

  /// No description provided for @auCodeLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {time}'**
  String auCodeLocked(String time);

  /// No description provided for @auBiometricAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get auBiometricAuthTitle;

  /// No description provided for @auBiometricAuthBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to use biometric authentication?'**
  String get auBiometricAuthBody;

  /// No description provided for @auBiometricSignInReason.
  ///
  /// In en, this message translates to:
  /// **'Use Touch ID to sign in to the app'**
  String get auBiometricSignInReason;

  /// No description provided for @auBiometricSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the app'**
  String get auBiometricSignInTitle;

  /// No description provided for @auBiometricFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get auBiometricFallbackTitle;

  /// No description provided for @auBiometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Touch ID is not supported on this device'**
  String get auBiometricNotSupported;

  /// No description provided for @auBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Touch ID is unavailable'**
  String get auBiometricUnavailable;

  /// No description provided for @auWrongAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Incorrect access code'**
  String get auWrongAccessCode;

  /// No description provided for @auMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get auMessageTitle;

  /// No description provided for @auYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get auYes;

  /// No description provided for @auNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get auNo;

  /// No description provided for @auVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter confirmation code'**
  String get auVerificationTitle;

  /// No description provided for @auVerificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get auVerificationCodeLabel;

  /// No description provided for @auVerificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get auVerificationCodeHint;

  /// No description provided for @auVerificationSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the code'**
  String get auVerificationSendFailed;

  /// No description provided for @auVerificationCodeLengthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 digits'**
  String get auVerificationCodeLengthInvalid;

  /// No description provided for @auVerificationInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get auVerificationInvalidCode;

  /// No description provided for @auVerificationCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify the code. Please try again'**
  String get auVerificationCheckFailed;

  /// No description provided for @auChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get auChangePassword;

  /// No description provided for @auLinkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get auLinkedAccounts;

  /// No description provided for @auChangeAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Change access code'**
  String get auChangeAccessCode;

  /// No description provided for @auAuthorizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get auAuthorizationTitle;

  /// No description provided for @auBiometricLoginDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the app with biometrics'**
  String get auBiometricLoginDesc;

  /// No description provided for @auScreenProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen recording protection'**
  String get auScreenProtectionTitle;

  /// No description provided for @auScreenProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Screenshots and screen recording'**
  String get auScreenProtectionDesc;

  /// No description provided for @auBiometricOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric operations'**
  String get auBiometricOperationsTitle;

  /// No description provided for @auBiometricOperationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Confirming transfers'**
  String get auBiometricOperationsDesc;

  /// No description provided for @auDeleteAccountRequest.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get auDeleteAccountRequest;

  /// No description provided for @auBiometricUnavailableDevice.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available on this device'**
  String get auBiometricUnavailableDevice;

  /// No description provided for @auBiometricAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Biometric confirmation required'**
  String get auBiometricAuthRequired;

  /// No description provided for @auBiometricChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Changing requires authorization'**
  String get auBiometricChangeHint;

  /// No description provided for @auEmailConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Email confirmation required'**
  String get auEmailConfirmationRequired;

  /// No description provided for @auConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirmation required'**
  String get auConfirmationRequired;

  /// No description provided for @auDeleteConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm account deletion.'**
  String get auDeleteConfirmHint;

  /// No description provided for @auProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get auProfileTitle;

  /// No description provided for @auMyNotifications.
  ///
  /// In en, this message translates to:
  /// **'My notifications'**
  String get auMyNotifications;

  /// No description provided for @auNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get auNotificationsTitle;

  /// No description provided for @auAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get auAppLanguage;

  /// No description provided for @auPhoneTransfers.
  ///
  /// In en, this message translates to:
  /// **'Phone transfers'**
  String get auPhoneTransfers;

  /// No description provided for @auAccountOperations.
  ///
  /// In en, this message translates to:
  /// **'Account operations'**
  String get auAccountOperations;

  /// No description provided for @auNoOperations.
  ///
  /// In en, this message translates to:
  /// **'No operations yet'**
  String get auNoOperations;

  /// No description provided for @auNoTransfers.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet'**
  String get auNoTransfers;

  /// No description provided for @auNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get auNoPayments;

  /// No description provided for @auTrustedPhone.
  ///
  /// In en, this message translates to:
  /// **'Your trusted number'**
  String get auTrustedPhone;

  /// No description provided for @auSecurityTip.
  ///
  /// In en, this message translates to:
  /// **'Do not follow unverified links and do not enter your personal data on unknown websites. Scammers may use fake links and pages to steal information. Always check the source of messages and make sure the website address belongs to your bank. Remember: bank employees will never ask for your password or an SMS code.'**
  String get auSecurityTip;

  /// No description provided for @auTxDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get auTxDeposit;

  /// No description provided for @auTxWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get auTxWithdrawal;

  /// No description provided for @auTxPhoneTransfer.
  ///
  /// In en, this message translates to:
  /// **'Phone transfer'**
  String get auTxPhoneTransfer;

  /// No description provided for @auTxQrTransfer.
  ///
  /// In en, this message translates to:
  /// **'QR transfer'**
  String get auTxQrTransfer;

  /// No description provided for @auTxCurrencyConversion.
  ///
  /// In en, this message translates to:
  /// **'Currency exchange'**
  String get auTxCurrencyConversion;

  /// No description provided for @auTxInternalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Internal transfer'**
  String get auTxInternalTransfer;

  /// No description provided for @auTxCardTransfer.
  ///
  /// In en, this message translates to:
  /// **'Card transfer'**
  String get auTxCardTransfer;

  /// No description provided for @auTxSwiftTransfer.
  ///
  /// In en, this message translates to:
  /// **'SWIFT transfer'**
  String get auTxSwiftTransfer;

  /// No description provided for @auTxTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get auTxTransfer;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @zhambylRegion.
  ///
  /// In en, this message translates to:
  /// **'Zhambyl region'**
  String get zhambylRegion;

  /// No description provided for @serviceMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get serviceMobile;

  /// No description provided for @serviceInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get serviceInternet;

  /// No description provided for @serviceTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get serviceTransport;

  /// No description provided for @serviceUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get serviceUtilities;

  /// No description provided for @openNewCard.
  ///
  /// In en, this message translates to:
  /// **'Open a new card'**
  String get openNewCard;

  /// No description provided for @creditCash.
  ///
  /// In en, this message translates to:
  /// **'Get a cash loan'**
  String get creditCash;

  /// No description provided for @creditCashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Online up to 7,000,000 KZT'**
  String get creditCashSubtitle;

  /// No description provided for @openDepositSubtitle.
  ///
  /// In en, this message translates to:
  /// **'At favorable terms'**
  String get openDepositSubtitle;

  /// No description provided for @multiCurrency.
  ///
  /// In en, this message translates to:
  /// **'Multi-currency'**
  String get multiCurrency;

  /// No description provided for @emptyAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get emptyAccounts;

  /// No description provided for @transferByPhone.
  ///
  /// In en, this message translates to:
  /// **'By phone number'**
  String get transferByPhone;

  /// No description provided for @transferByPhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'For individuals and businesses'**
  String get transferByPhoneDesc;

  /// No description provided for @transferBetweenOwn.
  ///
  /// In en, this message translates to:
  /// **'Between my accounts'**
  String get transferBetweenOwn;

  /// No description provided for @transferBetweenOwnDesc.
  ///
  /// In en, this message translates to:
  /// **'Cards, accounts, deposits'**
  String get transferBetweenOwnDesc;

  /// No description provided for @transferKz.
  ///
  /// In en, this message translates to:
  /// **'Within Kazakhstan'**
  String get transferKz;

  /// No description provided for @transferKzDesc.
  ///
  /// In en, this message translates to:
  /// **'To a card or account number'**
  String get transferKzDesc;

  /// No description provided for @transferInternational.
  ///
  /// In en, this message translates to:
  /// **'International transfers'**
  String get transferInternational;

  /// No description provided for @transferInternationalDesc.
  ///
  /// In en, this message translates to:
  /// **'Anywhere in the world'**
  String get transferInternationalDesc;

  /// No description provided for @conversionDesc.
  ///
  /// In en, this message translates to:
  /// **'Currency exchange'**
  String get conversionDesc;

  /// No description provided for @bankQr.
  ///
  /// In en, this message translates to:
  /// **'Bank QR'**
  String get bankQr;

  /// No description provided for @bankQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a QR to receive money'**
  String get bankQrDesc;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card details'**
  String get cardDetails;

  /// No description provided for @cardDetailsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Card data is not available'**
  String get cardDetailsEmpty;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @pendingAmount.
  ///
  /// In en, this message translates to:
  /// **'Pending: 0.00 KZT'**
  String get pendingAmount;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statement;

  /// No description provided for @incomeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income and expenses'**
  String get incomeExpenses;

  /// No description provided for @requisites.
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get requisites;

  /// No description provided for @accountNumbers.
  ///
  /// In en, this message translates to:
  /// **'Account numbers'**
  String get accountNumbers;

  /// No description provided for @closeCard.
  ///
  /// In en, this message translates to:
  /// **'Close card'**
  String get closeCard;

  /// No description provided for @renameCard.
  ///
  /// In en, this message translates to:
  /// **'Rename card'**
  String get renameCard;

  /// No description provided for @manageSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Manage subscriptions'**
  String get manageSubscriptions;

  /// No description provided for @orderCard.
  ///
  /// In en, this message translates to:
  /// **'Order a card'**
  String get orderCard;

  /// No description provided for @setLimits.
  ///
  /// In en, this message translates to:
  /// **'Set limits'**
  String get setLimits;

  /// No description provided for @getCertificate.
  ///
  /// In en, this message translates to:
  /// **'Get a certificate'**
  String get getCertificate;

  /// No description provided for @blocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get blocks;

  /// No description provided for @cardSettings.
  ///
  /// In en, this message translates to:
  /// **'Card settings'**
  String get cardSettings;

  /// No description provided for @portfolioTenge.
  ///
  /// In en, this message translates to:
  /// **'Portfolio in tenge'**
  String get portfolioTenge;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @paymentHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your payment history will appear here'**
  String get paymentHistoryEmpty;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get periodMonth;

  /// No description provided for @period3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get period3Months;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get periodCustom;

  /// No description provided for @periodCalendar.
  ///
  /// In en, this message translates to:
  /// **'Pick a period in calendar'**
  String get periodCalendar;

  /// No description provided for @choosePeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose a period'**
  String get choosePeriod;

  /// No description provided for @categoryThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get categoryThisWeek;

  /// No description provided for @categoryThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get categoryThisMonth;

  /// No description provided for @categoryEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get categoryEarlier;

  /// No description provided for @txDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get txDeposit;

  /// No description provided for @txWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get txWithdrawal;

  /// No description provided for @txPhoneTransfer.
  ///
  /// In en, this message translates to:
  /// **'Phone transfer'**
  String get txPhoneTransfer;

  /// No description provided for @txQrTransfer.
  ///
  /// In en, this message translates to:
  /// **'QR transfer'**
  String get txQrTransfer;

  /// No description provided for @txConversion.
  ///
  /// In en, this message translates to:
  /// **'Currency exchange'**
  String get txConversion;

  /// No description provided for @txInternalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Internal transfer'**
  String get txInternalTransfer;

  /// No description provided for @txCardTransfer.
  ///
  /// In en, this message translates to:
  /// **'Card transfer'**
  String get txCardTransfer;

  /// No description provided for @txSwiftTransfer.
  ///
  /// In en, this message translates to:
  /// **'SWIFT transfer'**
  String get txSwiftTransfer;

  /// No description provided for @txPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get txPayment;

  /// No description provided for @txOther.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get txOther;

  /// No description provided for @convertTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency conversion'**
  String get convertTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @linkedAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get linkedAccountsTitle;

  /// No description provided for @featurePlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This screen is not available yet.'**
  String get featurePlaceholderBody;

  /// No description provided for @recipientLookupLimited.
  ///
  /// In en, this message translates to:
  /// **'Recipient not found; try again later'**
  String get recipientLookupLimited;

  /// No description provided for @transferNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Try again.'**
  String get transferNetworkError;

  /// No description provided for @transferServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Try again later.'**
  String get transferServerError;

  /// No description provided for @transferAuthError.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get transferAuthError;

  /// No description provided for @transferValidationError.
  ///
  /// In en, this message translates to:
  /// **'Check the amount and recipient, then try again.'**
  String get transferValidationError;

  /// No description provided for @transferInsufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance.'**
  String get transferInsufficientFunds;

  /// No description provided for @transferRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate unavailable. Try again later.'**
  String get transferRateUnavailable;

  /// No description provided for @transferAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'Account is not active.'**
  String get transferAccountInactive;

  /// No description provided for @transferOverpayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment exceeds the outstanding debt.'**
  String get transferOverpayment;

  /// No description provided for @convertedAmount.
  ///
  /// In en, this message translates to:
  /// **'Converted amount'**
  String get convertedAmount;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get exchangeRate;

  /// No description provided for @transferTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a minute.'**
  String get transferTooManyRequests;

  /// No description provided for @bioSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is now available'**
  String get bioSetupTitle;

  /// No description provided for @bioSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in faster with your phone\'s biometric credentials instead of typing your access code.'**
  String get bioSetupBody;

  /// No description provided for @bioSetupEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric login'**
  String get bioSetupEnable;

  /// No description provided for @bioSetupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get bioSetupSkip;

  /// No description provided for @bioSetupDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is now set up'**
  String get bioSetupDoneTitle;

  /// No description provided for @bioSetupDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it off anytime from Settings.'**
  String get bioSetupDoneBody;

  /// No description provided for @bioSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get bioSetupContinue;

  /// No description provided for @bioSetupReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your fingerprint to enable biometric login'**
  String get bioSetupReason;

  /// No description provided for @bioSetupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get bioSetupUnavailable;

  /// No description provided for @bioSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enable biometric login. Please try again.'**
  String get bioSetupFailed;

  /// No description provided for @faceTitle.
  ///
  /// In en, this message translates to:
  /// **'Face verification'**
  String get faceTitle;

  /// No description provided for @faceIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get faceIntroTitle;

  /// No description provided for @faceIntroBody.
  ///
  /// In en, this message translates to:
  /// **'We check that a real person is using this account. It takes about 10 seconds. Video is analysed on your device and is not recorded or stored.'**
  String get faceIntroBody;

  /// No description provided for @faceTipCenter.
  ///
  /// In en, this message translates to:
  /// **'Center your face in the oval'**
  String get faceTipCenter;

  /// No description provided for @faceTipLight.
  ///
  /// In en, this message translates to:
  /// **'Stand in good, even lighting'**
  String get faceTipLight;

  /// No description provided for @faceTipObstruct.
  ///
  /// In en, this message translates to:
  /// **'Remove glasses, mask, hat or anything covering your face'**
  String get faceTipObstruct;

  /// No description provided for @faceTipStill.
  ///
  /// In en, this message translates to:
  /// **'Hold still when asked'**
  String get faceTipStill;

  /// No description provided for @faceStart.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get faceStart;

  /// No description provided for @faceUsePin.
  ///
  /// In en, this message translates to:
  /// **'Use access code instead'**
  String get faceUsePin;

  /// No description provided for @faceContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get faceContactSupport;

  /// No description provided for @faceHintNoFace.
  ///
  /// In en, this message translates to:
  /// **'Position your face in the oval'**
  String get faceHintNoFace;

  /// No description provided for @faceHintMultiple.
  ///
  /// In en, this message translates to:
  /// **'Only one face should be visible'**
  String get faceHintMultiple;

  /// No description provided for @faceHintCloser.
  ///
  /// In en, this message translates to:
  /// **'Move a little closer'**
  String get faceHintCloser;

  /// No description provided for @faceHintFarther.
  ///
  /// In en, this message translates to:
  /// **'Move a little farther'**
  String get faceHintFarther;

  /// No description provided for @faceHintCenter.
  ///
  /// In en, this message translates to:
  /// **'Center your face'**
  String get faceHintCenter;

  /// No description provided for @faceHintHold.
  ///
  /// In en, this message translates to:
  /// **'Hold still…'**
  String get faceHintHold;

  /// No description provided for @faceChallengeBlink.
  ///
  /// In en, this message translates to:
  /// **'Blink slowly'**
  String get faceChallengeBlink;

  /// No description provided for @faceChallengeSmile.
  ///
  /// In en, this message translates to:
  /// **'Smile'**
  String get faceChallengeSmile;

  /// No description provided for @faceChallengeTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn your head to one side, then back'**
  String get faceChallengeTurn;

  /// No description provided for @faceSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get faceSuccessTitle;

  /// No description provided for @faceSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your identity check is complete.'**
  String get faceSuccessBody;

  /// No description provided for @faceErrPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off'**
  String get faceErrPermissionTitle;

  /// No description provided for @faceErrPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to verify your face.'**
  String get faceErrPermissionBody;

  /// No description provided for @faceOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get faceOpenSettings;

  /// No description provided for @faceErrNoCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'No camera found'**
  String get faceErrNoCameraTitle;

  /// No description provided for @faceErrNoCameraBody.
  ///
  /// In en, this message translates to:
  /// **'This device has no usable front camera. Use your access code or contact support.'**
  String get faceErrNoCameraBody;

  /// No description provided for @faceErrTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan timed out'**
  String get faceErrTimeoutTitle;

  /// No description provided for @faceErrTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'The check could not be completed in time. Try again in better light.'**
  String get faceErrTimeoutBody;

  /// No description provided for @faceErrGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get faceErrGenericTitle;

  /// No description provided for @faceErrGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the camera. Please try again.'**
  String get faceErrGenericBody;

  /// No description provided for @faceSupportSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent. Support will review it. Until then you can use the app with limited access.'**
  String get faceSupportSent;

  /// No description provided for @faceSupportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request. Check your connection and try again.'**
  String get faceSupportFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
