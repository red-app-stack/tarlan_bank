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

  @override
  String get openApp => 'Қолданбаны ашу';

  @override
  String get navPayments => 'Төлемдер';

  @override
  String get navTransfers => 'Аударымдар';

  @override
  String get navAccounts => 'Шоттар';

  @override
  String get navMenu => 'Мәзір';

  @override
  String get searchHint => 'Іздеу...';

  @override
  String get transferByAccount => 'Шот нөмірі бойынша';

  @override
  String get conversion => 'Конвертация';

  @override
  String get mobileTransfer => 'Мобильді аударым';

  @override
  String get qrTransfer => 'QR аударым';

  @override
  String get ownAccounts => 'Өз шоттарым арасында';

  @override
  String get receipt => 'Төлем қвитанциясы';

  @override
  String get transferHistory => 'Аударымдар тарихы';

  @override
  String get from => 'Қайдан';

  @override
  String get to => 'Қайда';

  @override
  String get amount => 'Сома';

  @override
  String get recipientAccountNumber => 'Алушы шотының нөмірі';

  @override
  String get enterPhoneNumber => 'Телефон нөмірін енгізіңіз';

  @override
  String get recipient => 'Алушы';

  @override
  String get message => 'Хабар';

  @override
  String get messageHint => 'Алушыға хабар';

  @override
  String get scan => 'Сканирлеу';

  @override
  String get create => 'Жасау';

  @override
  String get createQrCode => 'QR код жасау';

  @override
  String get qrHint =>
      'Соманы көрсетпесеңіз, оны QR кодыңызды сканирлеген жіберуші енгізе алады';

  @override
  String get transferVerb => 'Аудару';

  @override
  String get errorSelectCard => 'Карточканы таңдаңыз';

  @override
  String get errorEnterAmount => 'Соманы енгізіңіз';

  @override
  String get errorEnterAccount => 'Дұрыс шот нөмірін енгізіңіз';

  @override
  String get errorEnterPhone => 'Телефон нөмірін енгізіңіз';

  @override
  String get recipientNotFound => 'Алушы табылмады';

  @override
  String get transferSuccess => 'Аударым сәтті орындалды';

  @override
  String get transferFailed => 'Аударым орындалмады';

  @override
  String get noAccounts => 'Сізде қолжетімді шоттар жоқ';

  @override
  String get noTransfers => 'Аударымдар тарихы мұнда көрсетіледі';

  @override
  String today(String date) {
    return 'Бүгін, $date';
  }

  @override
  String get week => 'Соңғы апта';

  @override
  String get month => 'Соңғы ай';

  @override
  String get threeMonths => 'Соңғы 3 ай';

  @override
  String get customPeriod => 'Таңдалған кезең';

  @override
  String get calendarPeriod => 'Күнтізбеден кезең таңдау';

  @override
  String get selectPeriod => 'Кезеңді таңдаңыз';

  @override
  String get choose => 'Таңдау';

  @override
  String get share => 'Бөлісу';

  @override
  String get repeat => 'Қайталау';

  @override
  String get cancelTransfer => 'Болдырмау';

  @override
  String get addToFavorites => 'Таңдаулыларға қосу';

  @override
  String get removeFromFavorites => 'Таңдаулылардан шығару';

  @override
  String get transactionType => 'Операция түрі';

  @override
  String get transactionId => 'Операция ID-сі';

  @override
  String get dateTime => 'Күні мен уақыты';

  @override
  String get commission => 'Комиссия';

  @override
  String get sender => 'Жіберуші';

  @override
  String get senderAccount => 'Жіберуші шоты';

  @override
  String get unknown => 'Белгісіз';

  @override
  String statusCompleted(String type) {
    return '$type сәтті орындалды';
  }

  @override
  String statusPending(String type) {
    return '$type өңделуде';
  }

  @override
  String statusFailed(String type) {
    return '$type орындалмады';
  }

  @override
  String get typeDeposit => 'Салым';

  @override
  String get typeWithdrawal => 'Шығару';

  @override
  String get typePhoneTransfer => 'Нөмір бойынша аударым';

  @override
  String get typeQrTransfer => 'QR аударым';

  @override
  String get typeCurrencyConversion => 'Валюта айырбастау';

  @override
  String get typeInternalTransfer => 'Ішкі аударым';

  @override
  String get typeCardTransfer => 'Карточкаға аудару';

  @override
  String get typeSwiftTransfer => 'SWIFT аударым';

  @override
  String get typeTransfer => 'Аударым';

  @override
  String get noTransaction => 'Операция таңдалмады';

  @override
  String get accountCurrent => 'Ағымдағы';

  @override
  String get accountDeposit => 'Депозит';

  @override
  String get accountCredit => 'Несие';

  @override
  String get auSettingsTitle => 'Параметрлер';

  @override
  String get auSettingsThemeTitle => 'Қолданба тақырыбы';

  @override
  String get auSettingsThemeSubtitle =>
      'Жарық, қараңғы немесе жүйелік тақырыпты таңдаңыз';

  @override
  String get auThemeSystem => 'Жүйелік';

  @override
  String get auThemeLight => 'Жарық';

  @override
  String get auThemeDark => 'Қараңғы';

  @override
  String get auSettingsQuickToggleTitle => 'Тақырыпты жылдам ауыстыру';

  @override
  String get auSettingsQuickToggleSubtitle =>
      'Жарық пен қараңғы арасында ауысу үшін түртіңіз';

  @override
  String get auCodeCreateTitle => 'Қол жеткізу кодын ойлап табыңыз';

  @override
  String get auCodeRepeatTitle => 'Қол жеткізу кодын қайталаңыз';

  @override
  String get auCodeEnterTitle => 'Қол жеткізу кодын енгізіңіз';

  @override
  String get auCodeResetButton => 'Қол жеткізу кодын қалпына келтіру';

  @override
  String get auCodeForgotButton => 'Қол жеткізу кодын ұмыттыңыз ба?';

  @override
  String auCodeLocked(String time) {
    return 'Тым көп әрекет. $time кейін қайталаңыз';
  }

  @override
  String get auBiometricAuthTitle => 'Биометриялық аутентификация';

  @override
  String get auBiometricAuthBody =>
      'Биометриялық аутентификацияны пайдаланғыңыз келе ме?';

  @override
  String get auBiometricSignInReason =>
      'Қолданбаға кіру үшін Touch ID пайдаланыңыз';

  @override
  String get auBiometricSignInTitle => 'Қолданбаға кіру';

  @override
  String get auBiometricFallbackTitle => 'Биометриялық аутентификация';

  @override
  String get auBiometricNotSupported =>
      'Touch ID бұл құрылғыда қолдау көрсетілмейді';

  @override
  String get auBiometricUnavailable => 'Touch ID қолжетімсіз';

  @override
  String get auWrongAccessCode => 'Қол жеткізу коды дұрыс емес';

  @override
  String get auMessageTitle => 'Хабарлама';

  @override
  String get auYes => 'Иә';

  @override
  String get auNo => 'Жоқ';

  @override
  String get auVerificationTitle => 'Растау кодын енгізіңіз';

  @override
  String get auVerificationCodeLabel => 'Растау коды';

  @override
  String get auVerificationCodeHint => '000000';

  @override
  String get auVerificationSendFailed => 'Кодды жіберу мүмкін болмады';

  @override
  String get auVerificationCodeLengthInvalid => 'Код 6 цифрадан тұруы керек';

  @override
  String get auVerificationInvalidCode => 'Код дұрыс емес';

  @override
  String get auVerificationCheckFailed =>
      'Кодды тексеру мүмкін болмады. Қайталаңыз';

  @override
  String get auChangePassword => 'Құпия сөзді өзгерту';

  @override
  String get auLinkedAccounts => 'Байланысты тіркелгілер';

  @override
  String get auChangeAccessCode => 'Қол жеткізу кодын өзгерту';

  @override
  String get auAuthorizationTitle => 'Авторизация';

  @override
  String get auBiometricLoginDesc => 'Қолданбаға биометриямен кіру';

  @override
  String get auScreenProtectionTitle => 'Экран жазудан қорғау';

  @override
  String get auScreenProtectionDesc => 'Скриншоттар және экран жазу';

  @override
  String get auBiometricOperationsTitle => 'Биометриялық операциялар';

  @override
  String get auBiometricOperationsDesc => 'Аударымдарды растау';

  @override
  String get auDeleteAccountRequest => 'Тіркелгіні жоюды сұрау';

  @override
  String get auBiometricUnavailableDevice =>
      'Бұл құрылғыда биометрия қолжетімсіз';

  @override
  String get auBiometricAuthRequired => 'Биометриямен растау қажет';

  @override
  String get auBiometricChangeHint => 'Өзгерту авторизацияны талап етеді';

  @override
  String get auEmailConfirmationRequired => 'Поштамен растау қажет';

  @override
  String get auConfirmationRequired => 'Растау қажет';

  @override
  String get auDeleteConfirmHint => 'Тіркелгіні жоюды растаңыз.';

  @override
  String get auProfileTitle => 'Профиль';

  @override
  String get auMyNotifications => 'Менің хабарландыруларым';

  @override
  String get auNotificationsTitle => 'Хабарландырулар';

  @override
  String get auAppLanguage => 'Қолданба тілі';

  @override
  String get auPhoneTransfers => 'Телефон нөмірі бойынша аударымдар';

  @override
  String get auAccountOperations => 'Шоттар бойынша операциялар';

  @override
  String get auNoOperations => 'Әзірге операциялар жоқ';

  @override
  String get auNoTransfers => 'Әзірге аударымдар жоқ';

  @override
  String get auNoPayments => 'Әзірге төлемдер жоқ';

  @override
  String get auTrustedPhone => 'Сіздің сенімді нөміріңіз';

  @override
  String get auSecurityTip =>
      'Тексерілмеген сілтемелерге өтпеңіз және жеке деректеріңізді бейтаныс веб-сайттарға енгізбеңіз. Алаяқтар ақпаратты ұрлау үшін жалған сілтемелер мен беттерді пайдалануы мүмкін. Хабарламалардың көзін әрдайым тексеріп, веб-сайт мекенжайының банкіңізге тиесілі екеніне көз жеткізіңіз. Есіңізде болсын: банк қызметкерлері ешқашан құпия сөзіңізді немесе SMS-кодты сұрамайды.';

  @override
  String get auTxDeposit => 'Салым';

  @override
  String get auTxWithdrawal => 'Шығару';

  @override
  String get auTxPhoneTransfer => 'Нөмір бойынша аудару';

  @override
  String get auTxQrTransfer => 'QR аудару';

  @override
  String get auTxCurrencyConversion => 'Валюта айырбастау';

  @override
  String get auTxInternalTransfer => 'Ішкі аудару';

  @override
  String get auTxCardTransfer => 'Картаға аудару';

  @override
  String get auTxSwiftTransfer => 'SWIFT аудару';

  @override
  String get auTxTransfer => 'Аудару';

  @override
  String get history => 'Тарих';

  @override
  String get popular => 'Танымал';

  @override
  String get favorites => 'Таңдаулылар';

  @override
  String get zhambylRegion => 'Жамбыл облысы';

  @override
  String get serviceMobile => 'Байланыс';

  @override
  String get serviceInternet => 'Интернет';

  @override
  String get serviceTransport => 'Көлік';

  @override
  String get serviceUtilities => 'Коммуналдық қызметтер';

  @override
  String get openNewCard => 'Жаңа карта ашу';

  @override
  String get creditCash => 'Қолма-қол несие алу';

  @override
  String get creditCashSubtitle => 'Онлайн 7 000 000 теңгеге дейін';

  @override
  String get openDepositSubtitle => 'Тиімді шарттарда';

  @override
  String get multiCurrency => 'Көп валюталы';

  @override
  String get emptyAccounts => 'Шоттар әлі жоқ';

  @override
  String get transferByPhone => 'Телефон нөмірі бойынша';

  @override
  String get transferByPhoneDesc => 'Жеке тұлғалар мен кәсіпкерлерге';

  @override
  String get transferBetweenOwn => 'Өз шоттарым арасында';

  @override
  String get transferBetweenOwnDesc => 'Карталар, шоттар, депозиттер';

  @override
  String get transferKz => 'Қазақстан ішінде';

  @override
  String get transferKzDesc => 'Картаға, шот нөміріне';

  @override
  String get transferInternational => 'Халықаралық аударымдар';

  @override
  String get transferInternationalDesc => 'Дүниежүзінің кез келген жеріне';

  @override
  String get conversionDesc => 'Валюта айырбастау';

  @override
  String get bankQr => 'Bank QR';

  @override
  String get bankQrDesc => 'Ақша алу үшін QR жасаңыз';

  @override
  String get saved => 'Сақталғандар';

  @override
  String get cardDetails => 'Карта мәліметтері';

  @override
  String get cardDetailsEmpty => 'Карта деректері қолжетімсіз';

  @override
  String get totalBalance => 'Жалпы баланс';

  @override
  String get pendingAmount => 'Өңделуде: 0,00 теңге';

  @override
  String get topUp => 'Толтыру';

  @override
  String get transfer => 'Аудару';

  @override
  String get withdraw => 'Шешу';

  @override
  String get statement => 'Үзінді';

  @override
  String get incomeExpenses => 'Кірістер мен шығыстар';

  @override
  String get requisites => 'Реквизиттер';

  @override
  String get accountNumbers => 'Шот нөмірлері';

  @override
  String get closeCard => 'Картаны жабу';

  @override
  String get renameCard => 'Карта атауын өзгерту';

  @override
  String get manageSubscriptions => 'Жазылымдарды басқару';

  @override
  String get orderCard => 'Картаға тапсырыс беру';

  @override
  String get setLimits => 'Лимиттерді орнату';

  @override
  String get getCertificate => 'Анықтама алу';

  @override
  String get blocks => 'Блокировкалар';

  @override
  String get cardSettings => 'Карта параметрлері';

  @override
  String get portfolioTenge => 'Портфель теңгеде';

  @override
  String get statistics => 'Статистика';

  @override
  String get operations => 'Операциялар';

  @override
  String get paymentHistory => 'Төлемдер тарихы';

  @override
  String get paymentHistoryEmpty => 'Төлемдер тарихыңыз мұнда көрсетіледі';

  @override
  String get periodWeek => 'Соңғы апта';

  @override
  String get periodMonth => 'Соңғы ай';

  @override
  String get period3Months => 'Соңғы 3 ай';

  @override
  String get periodCustom => 'Таңдалған кезең';

  @override
  String get periodCalendar => 'Күнтізбеден кезең таңдау';

  @override
  String get choosePeriod => 'Кезең таңдаңыз';

  @override
  String get categoryThisWeek => 'Осы аптада';

  @override
  String get categoryThisMonth => 'Осы айда';

  @override
  String get categoryEarlier => 'Бұрын';

  @override
  String get txDeposit => 'Салым';

  @override
  String get txWithdrawal => 'Шығару';

  @override
  String get txPhoneTransfer => 'Телефон бойынша аудару';

  @override
  String get txQrTransfer => 'QR аудару';

  @override
  String get txConversion => 'Валюта айырбастау';

  @override
  String get txInternalTransfer => 'Ішкі аудару';

  @override
  String get txCardTransfer => 'Картаға аудару';

  @override
  String get txSwiftTransfer => 'SWIFT аудару';

  @override
  String get txPayment => 'Төлем';

  @override
  String get txOther => 'Аудару';

  @override
  String get convertTitle => 'Валютаны айырбастау';

  @override
  String get changePasswordTitle => 'Құпия сөзді өзгерту';

  @override
  String get linkedAccountsTitle => 'Байланыстық тіркелгілер';

  @override
  String get featurePlaceholderBody => 'Бұл экран әзірге қолжетімді емес.';

  @override
  String get recipientLookupLimited => 'Алушы табылмады. Кейінірек қайталаңыз';

  @override
  String get transferNetworkError => 'Желі қолжетімсіз. Қайталаңыз.';

  @override
  String get transferServerError => 'Сервер қатесі. Кейінірек қайталаңыз.';

  @override
  String get transferAuthError => 'Сеанс аяқталды. Қайта кіріңіз.';

  @override
  String get transferValidationError =>
      'Сома мен алушыны тексеріп, қайталаңыз.';

  @override
  String get transferInsufficientFunds => 'Қаражат жеткіліксіз.';

  @override
  String get transferRateUnavailable =>
      'Бағам қолжетімсіз. Кейінірек қайталаңыз.';

  @override
  String get transferAccountInactive => 'Шот белсенді емес.';

  @override
  String get transferOverpayment => 'Төлем қарыздан асып кетті.';

  @override
  String get convertedAmount => 'Айналдырылған сома';

  @override
  String get exchangeRate => 'Айырбас бағамы';

  @override
  String get transferTooManyRequests =>
      'Тым көп әрекет. Бір минуттан кейін қайталаңыз.';

  @override
  String get bioSetupTitle => 'Биометриялық аутентификация енді қолжетімді';

  @override
  String get bioSetupBody =>
      'Кіру кодын енгізудің орнына телефон биометриясымен жылдам кіріңіз.';

  @override
  String get bioSetupEnable => 'Биометриялық кіруді қосу';

  @override
  String get bioSetupSkip => 'Қазір өтпей тұру';

  @override
  String get bioSetupDoneTitle => 'Биометриялық аутентификация орнатылды';

  @override
  String get bioSetupDoneBody =>
      'Оны кез келген уақытта Параметрлерде өшіруге болады.';

  @override
  String get bioSetupContinue => 'Жалғастыру';

  @override
  String get bioSetupReason =>
      'Биометриялық кіруді қосу үшін саусақ ізін растаңыз';

  @override
  String get bioSetupUnavailable =>
      'Биометриялық аутентификация бұл құрылғыда қолжетімсіз';

  @override
  String get bioSetupFailed =>
      'Биометриялық кіруді қосу мүмкін болмады. Қайталап көріңіз.';
}
