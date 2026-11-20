import 'account_model.dart';
import 'card_model.dart';

/// Accounts boundary (remodeled — see MIGRATION_PLAN.md D8).
///
/// One ledger collection `accounts/{number}` with product discriminator
/// (current/deposit/credit) + per-product terms; cards are separate
/// instruments (`cards/{id}`), never an account type.
///
/// Deliberately REMOVED vs the old REST interface: `deleteAccount` /
/// `deleteAllAccounts`. Bank accounts are closed via status, never hard
/// deleted — the ledger must stay auditable.
///
/// Methods throw a sealed [AppFailure] on error; lookups return null only
/// for "no such recipient", never to signal failure.
abstract interface class AccountsRepository {
  /// Realtime accounts of one owner, sorted (current first, then deposit,
  /// then credit — matches the old controller's display order).
  Stream<List<Account>> watchAccounts(String ownerId);

  Future<List<Account>> fetchAccounts(String ownerId);

  /// By 16-digit number. Throws [NotFoundFailure] when absent.
  Future<Account> getAccount(String number);

  /// Opens an account. Deposit/credit require matching product terms.
  /// For the owner's first current account, links it into `phone_index`
  /// so phone transfers can find it.
  Future<Account> createAccount({
    required String ownerId,
    required AccountType type,
    required String currency,
    DepositTerms? depositTerms,
    CreditTerms? creditTerms,
  });

  /// status → closed. Never deletes.
  Future<void> closeAccount(String number);

  /// Transfer recipient lookup. Exactly one argument must be given.
  /// Returns null when no matching account exists.
  Future<Account?> lookupAccount({String? phoneNumber, String? accountNumber});

  /// Realtime cards of one owner.
  Stream<List<BankCard>> watchCards(String ownerId);

  /// Issues a card linked to a CURRENT account. No CVV is generated or
  /// stored anywhere (PCI-DSS); only last4 of the account number.
  Future<BankCard> issueCard({
    required Account account,
    required String holderName,
    required int expiryMonth,
    required int expiryYear,
    String? label,
  });

  Future<void> setCardStatus(String cardId, CardStatus status);
}
