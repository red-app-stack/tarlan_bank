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
}
