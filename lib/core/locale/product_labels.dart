import 'package:tarlan_bank/generated/app_localizations.dart';

/// Product labels are already in lib/l10n/*.arb — never hardcode Russian in a
/// screen. Reused by create-account and any future product screen.
String productLabel(AppLocalizations l, String product) {
  switch (product.toLowerCase()) {
    case 'card':
      return l.createCard;
    case 'deposit':
      return l.createDeposit;
    case 'credit':
      return l.createCredit;
    case 'transfer':
      return l.createInstallment;
    default:
      return l.createCard;
  }
}

/// Document type keys are stable identifiers; the visible text is localized.
const documentTypeKeys = [
  'docTypeIdentity',
  'docTypePassportKz',
  'docTypeResidence',
  'docTypeStatelessKz',
  'docTypeForeignPassport',
  'docTypeStateless',
  'docTypeForeignStateless',
];

String documentTypeLabel(AppLocalizations l, String key) {
  switch (key) {
    case 'docTypePassportKz':
      return l.docTypePassportKz;
    case 'docTypeResidence':
      return l.docTypeResidence;
    case 'docTypeStatelessKz':
      return l.docTypeStatelessKz;
    case 'docTypeForeignPassport':
      return l.docTypeForeignPassport;
    case 'docTypeStateless':
      return l.docTypeStateless;
    case 'docTypeForeignStateless':
      return l.docTypeForeignStateless;
    case 'docTypeIdentity':
    default:
      return l.docTypeIdentity;
  }
}
