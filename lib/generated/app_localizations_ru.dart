// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Tarlan Bank';

  @override
  String get labelEnglish => 'Английский';

  @override
  String get labelRussian => 'Русский';

  @override
  String get labelKazakh => 'Казахский';

  @override
  String get success => 'Успех';

  @override
  String get error => 'Ошибка';

  @override
  String get errorGeneric => 'Что-то пошло не так';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get retry => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get later => 'Позже';

  @override
  String get loading => 'Загрузка…';

  @override
  String get orDivider => 'или';

  @override
  String get back => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get done => 'Готово';

  @override
  String get loginTitle => 'Вход в аккаунт';

  @override
  String get registerTitle => 'Создание аккаунта';

  @override
  String get fullName => 'ФИО';

  @override
  String get fullNameInvalid => 'Введите имя и фамилию';

  @override
  String get phone => 'Телефон';

  @override
  String get phoneInvalid => 'Введите номер в формате +7 701 234-56-78';

  @override
  String get email => 'Email';

  @override
  String get emailInvalid => 'Неверный email';

  @override
  String get password => 'Пароль';

  @override
  String get passwordRegister => 'Придумайте пароль';

  @override
  String get passwordRequired => 'Введите пароль';

  @override
  String get confirmPassword => 'Повторите пароль';

  @override
  String get passwordsMismatch => 'Пароли не совпадают';

  @override
  String get passwordStrong => 'Пароль подходит';

  @override
  String get passwordMinLength => 'Минимум 8 символов';

  @override
  String get passwordDigit => 'Нужна хотя бы одна цифра';

  @override
  String get passwordLetter => 'Нужна хотя бы одна буква';

  @override
  String get passwordSpecial => 'Нужен специальный символ (!@#\$%^&* и др.)';

  @override
  String get unexpectedError => 'Неожиданная ошибка. Попробуйте ещё раз';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Создать аккаунт';

  @override
  String get haveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get signInGoogle => 'Войти через Google';

  @override
  String get continueGuest => 'Продолжить как гость';

  @override
  String get guestHint => 'Гость: главная, меню и курсы валют';

  @override
  String get signInRequired => 'Войдите в аккаунт, чтобы открыть продукт';

  @override
  String get verifyTitle => 'Подтверждение email';

  @override
  String verifyBody(String email) {
    return 'Мы отправили письмо на $email. Перейдите по ссылке в письме, затем нажмите «Проверить».';
  }

  @override
  String get verifyCheck => 'Проверить';

  @override
  String get verifyResend => 'Отправить письмо ещё раз';

  @override
  String verifyResendIn(int seconds) {
    return 'Отправить снова через $seconds с';
  }

  @override
  String get verifyNotConfirmed =>
      'Письмо ещё не подтверждено. Перейдите по ссылке в почте';

  @override
  String get verifyLater => 'Позже';

  @override
  String get verifySignOut => 'Выйти';

  @override
  String get home => 'Главная';

  @override
  String get cards => 'Карты';

  @override
  String get deposits => 'Депозиты';

  @override
  String get credits => 'Кредиты';

  @override
  String get installment => 'Рассрочка';

  @override
  String get investments => 'Инвестиции';

  @override
  String get exchangeRates => 'Курс валют';

  @override
  String get menu => 'Меню';

  @override
  String get menuGuest => 'Меню (гость)';

  @override
  String get securitySettings => 'Настройки безопасности';

  @override
  String get products => 'Продукты';

  @override
  String get bankSection => 'Банк';

  @override
  String get atm => 'Банкоматы';

  @override
  String get branches => 'Отделения';

  @override
  String get callBank => 'Позвонить в Bank';

  @override
  String get supportTickets => 'Мои обращения в поддержку';

  @override
  String get logout => 'Выход';

  @override
  String get createCard => 'карту';

  @override
  String get createDeposit => 'депозит';

  @override
  String get createCredit => 'кредит';

  @override
  String get createInstallment => 'рассрочку';

  @override
  String get currency => 'Валюта';

  @override
  String interestRate(String rate) {
    return '$rate%';
  }

  @override
  String get personalInfo => 'Личные данные';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get financialInfo => 'Финансовая информация';

  @override
  String get monthlyIncome => 'Ежемесячный доход';

  @override
  String get additionalIncome => 'Дополнительный доход';

  @override
  String get documents => 'Документы';

  @override
  String get docType => 'Тип документа';

  @override
  String get docNumber => 'Номер документа';

  @override
  String get docExpiry => 'Действителен до';

  @override
  String get notUsCitizen =>
      'Я не являюсь гражданином / налогоплательщиком США';

  @override
  String openProduct(String product) {
    return 'Открыть $product';
  }

  @override
  String productOpened(String product) {
    return '$product успешно открыт';
  }

  @override
  String failedOpen(String product) {
    return 'Не удалось открыть $product';
  }

  @override
  String get docTypeIdentity => 'Удостоверение личности РК';

  @override
  String get docTypePassportKz => 'Паспорт гражданина РК';

  @override
  String get docTypeResidence => 'Вид на жительство иностранца в РК';

  @override
  String get docTypeStatelessKz =>
      'Удостоверение лица без гражданства, выданный РК';

  @override
  String get docTypeForeignPassport =>
      'Паспорт гражданина иностранного государства';

  @override
  String get docTypeStateless => 'Удостоверение лица без гражданства';

  @override
  String get docTypeForeignStateless => 'Паспорт иностранца без гражданства';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get openApp => 'Открыть приложение';

  @override
  String get navPayments => 'Платежи';

  @override
  String get navTransfers => 'Переводы';

  @override
  String get navAccounts => 'Счета';

  @override
  String get navMenu => 'Меню';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get transferByAccount => 'По номеру счета';

  @override
  String get conversion => 'Конвертация';

  @override
  String get mobileTransfer => 'Мобильный перевод';

  @override
  String get qrTransfer => 'Перевод по QR';

  @override
  String get ownAccounts => 'Между своими счетами';

  @override
  String get receipt => 'Квитанция';

  @override
  String get transferHistory => 'История переводов';

  @override
  String get from => 'Откуда';

  @override
  String get to => 'Куда';

  @override
  String get amount => 'Сумма';

  @override
  String get recipientAccountNumber => 'Номер счета получателя';

  @override
  String get enterPhoneNumber => 'Введите номер телефона';

  @override
  String get recipient => 'Получатель';

  @override
  String get message => 'Сообщение';

  @override
  String get messageHint => 'Сообщение отправителю';

  @override
  String get scan => 'Сканировать';

  @override
  String get create => 'Создать';

  @override
  String get createQrCode => 'Создать QR код';

  @override
  String get qrHint =>
      'Если не указать сумму перевода, она может быть указана отправителем при сканировании вашего QR';

  @override
  String get transferVerb => 'Перевести';

  @override
  String get errorSelectCard => 'Пожалуйста, выберите карту';

  @override
  String get errorEnterAmount => 'Пожалуйста, введите сумму';

  @override
  String get errorEnterAccount => 'Пожалуйста, введите корректный номер счета';

  @override
  String get errorEnterPhone => 'Пожалуйста, введите номер телефона';

  @override
  String get recipientNotFound => 'Получатель не найден';

  @override
  String get transferSuccess => 'Перевод успешно выполнен';

  @override
  String get transferFailed => 'Перевод не выполнен';

  @override
  String get noAccounts => 'У вас нет доступных счетов';

  @override
  String get noTransfers => 'Здесь будет отображаться история ваших переводов';

  @override
  String today(String date) {
    return 'Сегодня, $date';
  }

  @override
  String get week => 'За неделю';

  @override
  String get month => 'За месяц';

  @override
  String get threeMonths => 'За 3 месяца';

  @override
  String get customPeriod => 'Выбранный период';

  @override
  String get calendarPeriod => 'Выбрать период в календаре';

  @override
  String get selectPeriod => 'Выберите период';

  @override
  String get choose => 'Выбрать';

  @override
  String get share => 'Поделиться';

  @override
  String get repeat => 'Повторить';

  @override
  String get cancelTransfer => 'Отменить';

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get removeFromFavorites => 'Из избранного';

  @override
  String get transactionType => 'Тип транзакции';

  @override
  String get transactionId => 'ID транзакции';

  @override
  String get dateTime => 'Дата и время';

  @override
  String get commission => 'Комиссия';

  @override
  String get sender => 'Отправитель';

  @override
  String get senderAccount => 'Счет отправителя';

  @override
  String get unknown => 'Неизвестно';

  @override
  String statusCompleted(String type) {
    return '$type успешно выполнен';
  }

  @override
  String statusPending(String type) {
    return '$type в обработке';
  }

  @override
  String statusFailed(String type) {
    return '$type не выполнен';
  }

  @override
  String get typeDeposit => 'Вклад';

  @override
  String get typeWithdrawal => 'Вывод';

  @override
  String get typePhoneTransfer => 'Перевод по номеру';

  @override
  String get typeQrTransfer => 'QR перевод';

  @override
  String get typeCurrencyConversion => 'Обмен валюты';

  @override
  String get typeInternalTransfer => 'Внутренний перевод';

  @override
  String get typeCardTransfer => 'Перевод на карту';

  @override
  String get typeSwiftTransfer => 'SWIFT перевод';

  @override
  String get typeTransfer => 'Перевод';

  @override
  String get noTransaction => 'Транзакция не выбрана';

  @override
  String get accountCurrent => 'Текущий';

  @override
  String get accountDeposit => 'Депозит';

  @override
  String get accountCredit => 'Кредит';

  @override
  String get auSettingsTitle => 'Настройки';

  @override
  String get auSettingsThemeTitle => 'Тема приложения';

  @override
  String get auSettingsThemeSubtitle =>
      'Выберите светлую, тёмную или системную тему';

  @override
  String get auThemeSystem => 'Системная';

  @override
  String get auThemeLight => 'Светлая';

  @override
  String get auThemeDark => 'Тёмная';

  @override
  String get auSettingsQuickToggleTitle => 'Быстрое переключение темы';

  @override
  String get auSettingsQuickToggleSubtitle =>
      'Нажмите для переключения между светлой и тёмной темой';

  @override
  String get auCodeCreateTitle => 'Придумайте код доступа';

  @override
  String get auCodeRepeatTitle => 'Повторите код доступа';

  @override
  String get auCodeEnterTitle => 'Введите код доступа';

  @override
  String get auCodeResetButton => 'Сбросить код доступа';

  @override
  String get auCodeForgotButton => 'Забыли код доступа?';

  @override
  String auCodeLocked(String time) {
    return 'Слишком много попыток. Повторите через $time';
  }

  @override
  String get auBiometricAuthTitle => 'Биометрическая аутентификация';

  @override
  String get auBiometricAuthBody =>
      'Вы хотите использовать биометрическую аутентификацию?';

  @override
  String get auBiometricSignInReason =>
      'Используйте Touch ID для входа в приложение';

  @override
  String get auBiometricSignInTitle => 'Вход в приложение';

  @override
  String get auBiometricFallbackTitle => 'Биометрическая аутентификация';

  @override
  String get auBiometricNotSupported =>
      'Touch ID не поддерживается на этом устройстве';

  @override
  String get auBiometricUnavailable => 'Touch ID недоступен';

  @override
  String get auWrongAccessCode => 'Введен неверный код доступа';

  @override
  String get auMessageTitle => 'Сообщение';

  @override
  String get auYes => 'Да';

  @override
  String get auNo => 'Нет';

  @override
  String get auVerificationTitle => 'Введите код подтверждения';

  @override
  String get auVerificationCodeLabel => 'Код подтверждения';

  @override
  String get auVerificationCodeHint => '000000';

  @override
  String get auVerificationSendFailed => 'Не удалось отправить код';

  @override
  String get auVerificationCodeLengthInvalid => 'Код должен быть из 6 цифр';

  @override
  String get auVerificationInvalidCode => 'Неверный код';

  @override
  String get auVerificationCheckFailed =>
      'Не удалось проверить код. Попробуйте снова';

  @override
  String get auChangePassword => 'Смена пароля';

  @override
  String get auLinkedAccounts => 'Связанные аккаунты';

  @override
  String get auChangeAccessCode => 'Изменить код доступа';

  @override
  String get auAuthorizationTitle => 'Авторизация';

  @override
  String get auBiometricLoginDesc => 'Вход в приложение с биометрией';

  @override
  String get auScreenProtectionTitle => 'Защита от записи экрана';

  @override
  String get auScreenProtectionDesc => 'Скриншоты и запись экрана';

  @override
  String get auBiometricOperationsTitle => 'Операции с биометрией';

  @override
  String get auBiometricOperationsDesc => 'Подтверждение переводов';

  @override
  String get auDeleteAccountRequest => 'Запросить удаление учётной записи';

  @override
  String get auBiometricUnavailableDevice =>
      'Биометрия недоступна на этом устройстве';

  @override
  String get auBiometricAuthRequired => 'Необходимо подтверждение биометрией';

  @override
  String get auBiometricChangeHint => 'Изменение требует авторизации';

  @override
  String get auEmailConfirmationRequired => 'Необходимо подтверждение почтой';

  @override
  String get auConfirmationRequired => 'Необходимо подтверждение';

  @override
  String get auDeleteConfirmHint => 'Подтвердите удаление учётной записи.';

  @override
  String get auProfileTitle => 'Профиль';

  @override
  String get auMyNotifications => 'Мои уведомления';

  @override
  String get auNotificationsTitle => 'Уведомления';

  @override
  String get auAppLanguage => 'Язык приложения';

  @override
  String get auPhoneTransfers => 'Переводы по номеру телефона';

  @override
  String get auAccountOperations => 'Операции по счетам';

  @override
  String get auNoOperations => 'Пока нет операций';

  @override
  String get auNoTransfers => 'Пока нет переводов';

  @override
  String get auNoPayments => 'Пока нет платежей';

  @override
  String get auTrustedPhone => 'Ваш доверенный номер';

  @override
  String get auSecurityTip =>
      'Не переходите по непроверенным ссылкам и не вводите свои личные данные на неизвестных сайтах. Мошенники могут использовать поддельные ссылки и страницы для кражи информации. Всегда проверяйте источник сообщений и убедитесь, что адрес веб-сайта принадлежит вашему банку. Помните: сотрудники банка никогда не будут запрашивать ваш пароль или код из SMS.';

  @override
  String get auTxDeposit => 'Вклад';

  @override
  String get auTxWithdrawal => 'Вывод';

  @override
  String get auTxPhoneTransfer => 'Перевод по номеру';

  @override
  String get auTxQrTransfer => 'QR перевод';

  @override
  String get auTxCurrencyConversion => 'Обмен валюты';

  @override
  String get auTxInternalTransfer => 'Внутренний перевод';

  @override
  String get auTxCardTransfer => 'Перевод на карту';

  @override
  String get auTxSwiftTransfer => 'SWIFT перевод';

  @override
  String get auTxTransfer => 'Перевод';

  @override
  String get history => 'История';

  @override
  String get popular => 'Популярное';

  @override
  String get favorites => 'Избранное';

  @override
  String get zhambylRegion => 'Жамбылская обл.';

  @override
  String get serviceMobile => 'Связь';

  @override
  String get serviceInternet => 'Интернет';

  @override
  String get serviceTransport => 'Транспорт';

  @override
  String get serviceUtilities => 'Ком. услуги';

  @override
  String get openNewCard => 'Открыть новую карту';

  @override
  String get creditCash => 'Оформить кредит наличными';

  @override
  String get creditCashSubtitle => 'Онлайн до 7 000 000 тенге';

  @override
  String get openDepositSubtitle => 'На выгодных условиях';

  @override
  String get multiCurrency => 'Мультивалютная';

  @override
  String get emptyAccounts => 'Счетов пока нет';

  @override
  String get transferByPhone => 'По номеру телефона';

  @override
  String get transferByPhoneDesc => 'Клиентам и предпринимателям';

  @override
  String get transferBetweenOwn => 'Между своими счетами';

  @override
  String get transferBetweenOwnDesc => 'Картами, счетами, депозитами';

  @override
  String get transferKz => 'Внутри Казахстана';

  @override
  String get transferKzDesc => 'На карту, на номер счёта';

  @override
  String get transferInternational => 'Международные переводы';

  @override
  String get transferInternationalDesc => 'В любую точку мира';

  @override
  String get conversionDesc => 'Конвертация валют';

  @override
  String get bankQr => 'Bank QR';

  @override
  String get bankQrDesc => 'Создайте QR для получения перевода';

  @override
  String get saved => 'Сохраненные';

  @override
  String get cardDetails => 'Детали карты';

  @override
  String get cardDetailsEmpty => 'Данные карты недоступны';

  @override
  String get totalBalance => 'Общий баланс';

  @override
  String get pendingAmount => 'Сумма в обработке: 0,00 KZT';

  @override
  String get topUp => 'Пополнить';

  @override
  String get transfer => 'Перевести';

  @override
  String get withdraw => 'Снять';

  @override
  String get statement => 'Выписка';

  @override
  String get incomeExpenses => 'Доходы и расходы';

  @override
  String get requisites => 'Реквизиты';

  @override
  String get accountNumbers => 'Номера счетов';

  @override
  String get closeCard => 'Закрыть карту';

  @override
  String get renameCard => 'Переименовать карту';

  @override
  String get manageSubscriptions => 'Управление подписками';

  @override
  String get orderCard => 'Заказать карту';

  @override
  String get setLimits => 'Установить лимиты';

  @override
  String get getCertificate => 'Получить справку';

  @override
  String get blocks => 'Блокировки';

  @override
  String get cardSettings => 'Настройки карты';

  @override
  String get portfolioTenge => 'Портфель в тенге';

  @override
  String get statistics => 'Статистика';

  @override
  String get operations => 'Операции';

  @override
  String get paymentHistory => 'История платежей';

  @override
  String get paymentHistoryEmpty =>
      'Здесь будет отображаться история ваших платежей';

  @override
  String get periodWeek => 'За неделю';

  @override
  String get periodMonth => 'За месяц';

  @override
  String get period3Months => 'За 3 месяца';

  @override
  String get periodCustom => 'Выбранный период';

  @override
  String get periodCalendar => 'Выбрать период в календаре';

  @override
  String get choosePeriod => 'Выберите период';

  @override
  String get categoryThisWeek => 'На этой неделе';

  @override
  String get categoryThisMonth => 'Этот месяц';

  @override
  String get categoryEarlier => 'Ранее';

  @override
  String get txDeposit => 'Вклад';

  @override
  String get txWithdrawal => 'Вывод';

  @override
  String get txPhoneTransfer => 'Перевод по номеру';

  @override
  String get txQrTransfer => 'QR перевод';

  @override
  String get txConversion => 'Обмен валюты';

  @override
  String get txInternalTransfer => 'Внутренний перевод';

  @override
  String get txCardTransfer => 'Перевод на карту';

  @override
  String get txSwiftTransfer => 'SWIFT перевод';

  @override
  String get txPayment => 'Платеж';

  @override
  String get txOther => 'Перевод';

  @override
  String get convertTitle => 'Конвертация';

  @override
  String get changePasswordTitle => 'Смена пароля';

  @override
  String get linkedAccountsTitle => 'Связанные аккаунты';

  @override
  String get featurePlaceholderBody => 'Этот экран пока недоступен.';

  @override
  String get recipientLookupLimited => 'Получатель не найден. Попробуйте позже';

  @override
  String get transferNetworkError => 'Нет сети. Попробуйте снова.';

  @override
  String get transferServerError => 'Ошибка сервера. Попробуйте позже.';

  @override
  String get transferAuthError => 'Сессия истекла. Войдите снова.';

  @override
  String get transferValidationError =>
      'Проверьте сумму и получателя и попробуйте снова.';

  @override
  String get transferInsufficientFunds => 'Недостаточно средств.';

  @override
  String get transferRateUnavailable => 'Курс недоступен. Попробуйте позже.';

  @override
  String get transferAccountInactive => 'Счёт не активен.';

  @override
  String get transferOverpayment => 'Платёж превышает задолженность.';

  @override
  String get convertedAmount => 'Сумма после конвертации';

  @override
  String get exchangeRate => 'Курс обмена';

  @override
  String get transferTooManyRequests =>
      'Слишком много попыток. Попробуйте через минуту.';

  @override
  String get bioSetupTitle => 'Биометрическая аутентификация теперь доступна';

  @override
  String get bioSetupBody =>
      'Входите быстрее с помощью биометрии телефона вместо ввода кода доступа.';

  @override
  String get bioSetupEnable => 'Включить вход по биометрии';

  @override
  String get bioSetupSkip => 'Пока пропустить';

  @override
  String get bioSetupDoneTitle => 'Биометрическая аутентификация настроена';

  @override
  String get bioSetupDoneBody => 'Отключить её можно в настройках.';

  @override
  String get bioSetupContinue => 'Продолжить';

  @override
  String get bioSetupReason =>
      'Подтвердите отпечаток пальца, чтобы включить вход по биометрии';

  @override
  String get bioSetupUnavailable =>
      'Биометрическая аутентификация недоступна на этом устройстве';

  @override
  String get bioSetupFailed =>
      'Не удалось включить вход по биометрии. Попробуйте ещё раз.';

  @override
  String get faceTitle => 'Проверка лица';

  @override
  String get faceIntroTitle => 'Подтвердите личность';

  @override
  String get faceIntroBody =>
      'Мы проверяем, что аккаунтом пользуется реальный человек. Это займёт около 10 секунд. Видео анализируется на вашем устройстве и не записывается и не хранится.';

  @override
  String get faceTipCenter => 'Расположите лицо по центру овала';

  @override
  String get faceTipLight => 'Встаньте при хорошем ровном освещении';

  @override
  String get faceTipObstruct =>
      'Снимите очки, маску, головной убор и всё, что закрывает лицо';

  @override
  String get faceTipStill => 'Не двигайтесь, когда попросят';

  @override
  String get faceStart => 'Начать сканирование';

  @override
  String get faceUsePin => 'Использовать код доступа';

  @override
  String get faceContactSupport => 'Связаться с поддержкой';

  @override
  String get faceHintNoFace => 'Расположите лицо в овале';

  @override
  String get faceHintMultiple => 'В кадре должно быть только одно лицо';

  @override
  String get faceHintCloser => 'Подвиньтесь чуть ближе';

  @override
  String get faceHintFarther => 'Отодвиньтесь чуть дальше';

  @override
  String get faceHintCenter => 'Поместите лицо по центру';

  @override
  String get faceHintHold => 'Не двигайтесь…';

  @override
  String get faceChallengeBlink => 'Медленно моргните';

  @override
  String get faceChallengeSmile => 'Улыбнитесь';

  @override
  String get faceChallengeTurn => 'Поверните голову в сторону, затем обратно';

  @override
  String get faceSuccessTitle => 'Проверка пройдена';

  @override
  String get faceSuccessBody => 'Проверка личности завершена.';

  @override
  String get faceErrPermissionTitle => 'Нет доступа к камере';

  @override
  String get faceErrPermissionBody =>
      'Разрешите доступ к камере, чтобы пройти проверку лица.';

  @override
  String get faceOpenSettings => 'Открыть настройки';

  @override
  String get faceErrNoCameraTitle => 'Камера не найдена';

  @override
  String get faceErrNoCameraBody =>
      'На этом устройстве нет подходящей фронтальной камеры. Используйте код доступа или обратитесь в поддержку.';

  @override
  String get faceErrTimeoutTitle => 'Время сканирования истекло';

  @override
  String get faceErrTimeoutBody =>
      'Не удалось завершить проверку вовремя. Попробуйте ещё раз при лучшем освещении.';

  @override
  String get faceErrGenericTitle => 'Сканирование не удалось';

  @override
  String get faceErrGenericBody =>
      'Возникла проблема с камерой. Попробуйте ещё раз.';

  @override
  String get faceSupportSent =>
      'Запрос отправлен. Поддержка рассмотрит его. До этого приложение доступно с ограничениями.';

  @override
  String get faceSupportFailed =>
      'Не удалось отправить запрос. Проверьте соединение и попробуйте ещё раз.';
}
