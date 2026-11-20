// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'Tarlan Bank';

  @override
  String get labelEnglish => 'Ағылшын';

  @override
  String get labelRussian => 'Орыс';

  @override
  String get labelKazakh => 'Қазақ';

  @override
  String get success => 'Сәтті';

  @override
  String get error => 'Қате';

  @override
  String get errorGeneric => 'Бір нәрсе дұрыс болмады';

  @override
  String get cancel => 'Болдырмау';

  @override
  String get confirm => 'Растау';

  @override
  String get retry => 'Қайталау';

  @override
  String get close => 'Жабу';

  @override
  String get later => 'Кейін';

  @override
  String get loading => 'Жүктелуде…';

  @override
  String get orDivider => 'немесе';

  @override
  String get back => 'Артқа';

  @override
  String get next => 'Кейінгі';

  @override
  String get done => 'Дайын';

  @override
  String get loginTitle => 'Жүйеге кіру';

  @override
  String get registerTitle => 'Тіркелгі жасау';

  @override
  String get fullName => 'Аты-жөні';

  @override
  String get fullNameInvalid => 'Аты мен фамилияңызды енгізіңіз';

  @override
  String get phone => 'Телефон';

  @override
  String get phoneInvalid => '+7 701 234-56-78 форматында енгізіңіз';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Email дұрыс емес';

  @override
  String get password => 'Құпия сөз';

  @override
  String get passwordRegister => 'Құпия сөз ойлап табыңыз';

  @override
  String get passwordRequired => 'Құпия сөзді енгізіңіз';

  @override
  String get confirmPassword => 'Құпия сөзді қайталаңыз';

  @override
  String get passwordsMismatch => 'Құпия сөздер сәйкес келмейді';

  @override
  String get passwordStrong => 'Құпия сөз жарамды';

  @override
  String get passwordMinLength => 'Кемінде 8 таңба';

  @override
  String get passwordDigit => 'Кемінде бір сан керек';

  @override
  String get passwordLetter => 'Кемінде бір әріп керек';

  @override
  String get passwordSpecial => 'Арнайы таңба керек (!@#\$%^&* т.б.)';

  @override
  String get unexpectedError => 'Күтпеген қате. Қайталап көріңіз';

  @override
  String get signIn => 'Кіру';

  @override
  String get signUp => 'Тіркелгі жасау';

  @override
  String get haveAccount => 'Тіркелгіңіз бар ма? Кіру';

  @override
  String get noAccount => 'Тіркелгіңіз жоқ па? Тіркелу';

  @override
  String get signInGoogle => 'Google арқылы кіру';

  @override
  String get continueGuest => 'Қонақ ретінде жалғастыру';

  @override
  String get guestHint => 'Қонақ: басты бет, мәзір және валюта бағамы';

  @override
  String get signInRequired => 'Өнімді ашу үшін жүйеге кіріңіз';

  @override
  String get verifyTitle => 'Email растау';

  @override
  String verifyBody(String email) {
    return 'Біз $email мекенжайына хат жібердік. Хаттағы сілтемеге өтіп, «Тексеру» батырмасын басыңыз.';
  }

  @override
  String get verifyCheck => 'Тексеру';

  @override
  String get verifyResend => 'Хатты қайта жіберу';

  @override
  String verifyResendIn(int seconds) {
    return '$seconds с ішінде қайта жіберу';
  }

  @override
  String get verifyNotConfirmed =>
      'Хат әлі расталмады. Поштадағы сілтемеге өтіңіз';

  @override
  String get verifyLater => 'Кейін';

  @override
  String get verifySignOut => 'Шығу';

  @override
  String get home => 'Басты бет';

  @override
  String get cards => 'Карточкалар';

  @override
  String get deposits => 'Депозиттер';

  @override
  String get credits => 'Несиелер';

  @override
  String get installment => 'Бөліп төлеу';

  @override
  String get investments => 'Инвестициялар';

  @override
  String get exchangeRates => 'Валюта бағамы';

  @override
  String get menu => 'Мәзір';

  @override
  String get menuGuest => 'Мәзір (қонақ)';

  @override
  String get securitySettings => 'Қауіпсіздік параметрлері';

  @override
  String get products => 'Өнімдер';

  @override
  String get bankSection => 'Банк';

  @override
  String get atm => 'Банкоматтар';

  @override
  String get branches => 'Бөлімшелер';

  @override
  String get callBank => 'Банкке қоңырау шалу';

  @override
  String get supportTickets => 'Қолдау қызметіне өтініштерім';

  @override
  String get logout => 'Шығу';

  @override
  String get createCard => 'карточканы';

  @override
  String get createDeposit => 'депозитті';

  @override
  String get createCredit => 'несиені';

  @override
  String get createInstallment => 'бөліп төлеуді';

  @override
  String get currency => 'Валюта';

  @override
  String interestRate(String rate) {
    return '$rate%';
  }

  @override
  String get personalInfo => 'Жеке деректер';

  @override
  String get birthDate => 'Туған күні';

  @override
  String get financialInfo => 'Қаржылық мәліметтер';

  @override
  String get monthlyIncome => 'Айлық табыс';

  @override
  String get additionalIncome => 'Қосымша табыс';

  @override
  String get documents => 'Құжаттар';

  @override
  String get docType => 'Құжат түрі';

  @override
  String get docNumber => 'Құжат нөмірі';

  @override
  String get docExpiry => 'Жарамдылық мерзімі';

  @override
  String get notUsCitizen => 'Мен АҚШ азаматы / салық төлеушісі емеспін';

  @override
  String openProduct(String product) {
    return '$product ашу';
  }

  @override
  String productOpened(String product) {
    return '$product сәтті ашылды';
  }

  @override
  String failedOpen(String product) {
    return '$product ашылмады';
  }

  @override
  String get docTypeIdentity => 'ҚР жеке куәлігі';

  @override
  String get docTypePassportKz => 'ҚР азаматының төлқұжаты';

  @override
  String get docTypeResidence => 'ҚР-да тұруға рұқсат';

  @override
  String get docTypeStatelessKz => 'ҚР берген азаматтығы жоқ адам куәлігі';

  @override
  String get docTypeForeignPassport => 'Шет мемлекеттің төлқұжаты';

  @override
  String get docTypeStateless => 'Азаматтығы жоқ адам куәлігі';

  @override
  String get docTypeForeignStateless => 'Азаматтығы жоқ шет елдік төлқұжат';

  @override
  String get showPassword => 'Құпия сөзді көрсету';

  @override
  String get hidePassword => 'Құпия сөзді жасыру';
}
