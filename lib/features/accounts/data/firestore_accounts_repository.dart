import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/core/errors/firebase_error_mapping.dart';
import 'package:tarlan_bank/core/firebase/firestore_db.dart';
import 'package:tarlan_bank/core/utils/phone_number.dart';

import '../../transactions/data/recipient_lookup.dart';

import 'account_model.dart';
import 'accounts_repository.dart';
import 'card_model.dart';

/// Generates a 16-digit account number (first digit non-zero). Pure given a
/// [Random] so tests can seed it. Uniqueness is enforced by the Firestore
/// document ID — [FirestoreAccountsRepository.createAccount] retries on
/// collision.
String generateAccountNumber(Random random) {
  final buffer = StringBuffer()..write(random.nextInt(9) + 1);
  for (var i = 1; i < 16; i++) {
    buffer.write(random.nextInt(10));
  }
  return buffer.toString();
}

/// Firestore implementation of [AccountsRepository] (database `tarlan`).
///
/// Money-moving writes (transfers) live in TransactionsRepository, not here;
/// this repo only opens/closes accounts and manages cards. Balance changes
/// it does make (none today) would go through the same rules invariants.
class FirestoreAccountsRepository implements AccountsRepository {
  FirestoreAccountsRepository({FirebaseFirestore? firestore, Random? random})
    : _db = firestore ?? tarlanFirestore(),
      _random = random ?? Random.secure();

  final FirebaseFirestore _db;
  final Random _random;

  static const _currencies = ['USD', 'EUR', 'KZT'];

  /// Every new full account starts with one KZT debit card holding this much.
  static const double starterBalance = 50000;

  /// Cards issued at seeding expire five years out, on the same month.
  static ({int month, int year}) starterCardExpiry(DateTime now) =>
      (month: now.month, year: now.year + 5);

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _db.collection('accounts');
  CollectionReference<Map<String, dynamic>> get _cards =>
      _db.collection('cards');

  List<Account> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(Account.fromFirestore).toList()
      ..sort((a, b) {
        final byType = a.type.index.compareTo(b.type.index);
        return byType != 0 ? byType : a.number.compareTo(b.number);
      });
    return list;
  }

  @override
  Stream<List<Account>> watchAccounts(String ownerId) {
    return _accounts
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(_sorted)
        .handleError((Object e) => throw mapFirebaseError(e));
  }

  @override
  Future<List<Account>> fetchAccounts(String ownerId) async {
    try {
      final snap = await _accounts.where('ownerId', isEqualTo: ownerId).get();
      return _sorted(snap);
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<Account> getAccount(String number) async {
    try {
      final doc = await _accounts.doc(number).get();
      if (!doc.exists) throw NotFoundFailure('Account $number not found');
      return Account.fromFirestore(doc);
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<Account> createAccount({
    required String ownerId,
    required AccountType type,
    required String currency,
    double initialBalance = 0,
    DepositTerms? depositTerms,
    CreditTerms? creditTerms,
  }) async {
    if (!_currencies.contains(currency)) {
      throw ValidationFailure('Unsupported currency: $currency');
    }
    if (initialBalance < 0) {
      throw const ValidationFailure('Balance cannot be negative');
    }
    if (type == AccountType.deposit && depositTerms == null) {
      throw const ValidationFailure('Deposit accounts require product terms');
    }
    if (type == AccountType.credit && creditTerms == null) {
      throw const ValidationFailure('Credit accounts require product terms');
    }
    if (type == AccountType.debit &&
        (depositTerms != null || creditTerms != null)) {
      throw const ValidationFailure('Debit accounts carry no product terms');
    }

    try {
      // Doc ID = account number → UNIQUE. Retry on the (astronomically rare)
      // collision instead of trusting randomness alone.
      for (var attempt = 0; attempt < 5; attempt++) {
        final number = generateAccountNumber(_random);
        final data = <String, dynamic>{
          'number': number,
          'ownerId': ownerId,
          'type': type.name,
          'currency': currency,
          'balance': initialBalance,
          'status': AccountStatus.active.name,
          'createdAt': FieldValue.serverTimestamp(),
          if (depositTerms != null) 'terms': depositTerms.toMap(),
          if (creditTerms != null) 'terms': creditTerms.toMap(),
        };
        try {
          await _accounts.doc(number).set(data);
          final fullName = await _ownFullName(ownerId);
          await _writeRecipientIndex(ownerId, number, fullName);
          if (type == AccountType.debit) {
            await _linkPhoneIndex(ownerId, number, fullName);
          }
          return await getAccount(number);
        } on FirebaseException catch (e) {
          if (e.code == 'already-exists') continue;
          rethrow;
        }
      }
      throw const UnknownFailure('Could not allocate a unique account number');
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<Account> ensureStarterDebitAccount({required String ownerId}) async {
    final existing = await fetchAccounts(ownerId);
    final debit = existing.where((a) => a.type == AccountType.debit).toList();
    if (debit.isNotEmpty) return debit.first;

    final account = await createAccount(
      ownerId: ownerId,
      type: AccountType.debit,
      currency: 'KZT',
      initialBalance: starterBalance,
    );
    final holderName = await _ownFullName(ownerId);
    final expiry = starterCardExpiry(DateTime.now());
    await issueCard(
      account: account,
      holderName: holderName.trim().isEmpty ? 'Tarlan Bank' : holderName,
      expiryMonth: expiry.month,
      expiryYear: expiry.year,
    );
    return account;
  }

  /// First debit account becomes the phone-transfer target. Later debit
  /// accounts do not overwrite it (recipient stability).
  Future<String> _ownFullName(String ownerId) async {
    final doc = await _db.collection('users').doc(ownerId).get();
    return doc.data()?['fullName'] as String? ?? '';
  }

  Future<void> _writeRecipientIndex(
    String ownerId,
    String number,
    String fullName,
  ) async {
    if (fullName.trim().isEmpty) return;
    await _db.collection('recipient_index').doc(number).set({
      'uid': ownerId,
      'accountNumber': number,
      'fullName': fullName,
    }, SetOptions(merge: true));
  }

  Future<void> _linkPhoneIndex(
    String ownerId,
    String number, [
    String? fullName,
  ]) async {
    final name = fullName ?? await _ownFullName(ownerId);
    final doc = await _db.collection('users').doc(ownerId).get();
    final phone = doc.data()?['phoneNumber'] as String?;
    if (phone == null || phone.isEmpty || name.trim().isEmpty) return;
    final ref = _db.collection('phone_index').doc(normalizePhone(phone));
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': ownerId,
        'accountNumber': number,
        'fullName': name,
      });
    } else if (snap.data()?['accountNumber'] == null ||
        snap.data()?['fullName'] == null) {
      await ref.update({'accountNumber': number, 'fullName': name});
    }
  }

  @override
  Future<void> ensureRecipientIndexes(String ownerId) async {
    final fullName = await _ownFullName(ownerId);
    if (fullName.trim().isEmpty) return;
    final snap = await _accounts.where('ownerId', isEqualTo: ownerId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(_db.collection('recipient_index').doc(doc.id), {
        'uid': ownerId,
        'accountNumber': doc.id,
        'fullName': fullName,
      }, SetOptions(merge: true));
    }
    final profile = await _db.collection('users').doc(ownerId).get();
    final phone = profile.data()?['phoneNumber'] as String?;
    if (phone != null && phone.isNotEmpty) {
      for (final candidate in phoneIndexCandidates(phone)) {
        final indexDoc = await _db
            .collection('phone_index')
            .doc(candidate)
            .get();
        if (indexDoc.exists && indexDoc.data()?['uid'] == ownerId) {
          batch.set(_db.collection('phone_index').doc(candidate), {
            'fullName': fullName,
          }, SetOptions(merge: true));
        }
      }
    }
    await batch.commit();
  }

  @override
  Future<void> closeAccount(String number) async {
    try {
      await _accounts.doc(number).update({
        'status': AccountStatus.closed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<Account?> lookupAccount({
    String? phoneNumber,
    String? accountNumber,
  }) async {
    if ((phoneNumber == null) == (accountNumber == null)) {
      throw const ValidationFailure(
        'Provide exactly one of phoneNumber / accountNumber',
      );
    }
    try {
      if (accountNumber != null) {
        return await getAccount(accountNumber);
      }
      final index = await _db
          .collection('phone_index')
          .doc(normalizePhone(phoneNumber!))
          .get();
      final target = index.data()?['accountNumber'] as String?;
      if (!index.exists || target == null) return null;
      return await getAccount(target);
    } on NotFoundFailure {
      return null; // "no such recipient" is a normal lookup outcome
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<TransferRecipient?> lookupRecipient({
    String? phoneNumber,
    String? accountNumber,
  }) async {
    if ((phoneNumber == null) == (accountNumber == null)) {
      throw const ValidationFailure(
        'Provide exactly one of phoneNumber / accountNumber',
      );
    }
    try {
      if (accountNumber != null) {
        final doc = await _db
            .collection('recipient_index')
            .doc(accountNumber)
            .get();
        final data = doc.data();
        if (!doc.exists || data == null) return null;
        final name = data['fullName'] as String? ?? '';
        if (name.trim().isEmpty) return null;
        return TransferRecipient(
          uid: data['uid'] as String? ?? '',
          fullName: name,
          accountNumber: accountNumber,
        );
      }
      for (final candidate in phoneIndexCandidates(phoneNumber!)) {
        final doc = await _db.collection('phone_index').doc(candidate).get();
        final data = doc.data();
        if (!doc.exists || data == null) continue;
        var name = data['fullName'] as String? ?? '';
        final number = data['accountNumber'] as String? ?? '';
        if (name.trim().isEmpty && number.isNotEmpty) {
          final profileDoc = await _db
              .collection('recipient_index')
              .doc(number)
              .get();
          name = profileDoc.data()?['fullName'] as String? ?? '';
        }
        if (name.trim().isEmpty || number.isEmpty) continue;
        return TransferRecipient(
          uid: data['uid'] as String? ?? '',
          fullName: name,
          accountNumber: number,
          phoneNumber: candidate,
        );
      }
      return null;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Stream<List<BankCard>> watchCards(String ownerId) {
    return _cards
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs.map(BankCard.fromFirestore).toList())
        .handleError((Object e) => throw mapFirebaseError(e));
  }

  @override
  Future<BankCard> issueCard({
    required Account account,
    required String holderName,
    required int expiryMonth,
    required int expiryYear,
    String? label,
  }) async {
    if (account.type != AccountType.debit) {
      throw const ValidationFailure('Cards link to debit accounts only');
    }
    if (expiryMonth < 1 || expiryMonth > 12) {
      throw const ValidationFailure('Invalid expiry month');
    }
    final now = DateTime.now();
    final expiry = DateTime(expiryYear, expiryMonth + 1);
    if (!expiry.isAfter(now)) {
      throw const ValidationFailure('Card expiry must be in the future');
    }
    try {
      final id = const Uuid().v4();
      final card = BankCard(
        id: id,
        accountId: account.number,
        ownerId: account.ownerId,
        last4: account.number.substring(account.number.length - 4),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        holderName: holderName,
        status: CardStatus.active,
        label: label,
      );
      await _cards.doc(id).set({
        ...card.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return card;
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }

  @override
  Future<void> setCardStatus(String cardId, CardStatus status) async {
    try {
      await _cards.doc(cardId).update({'status': status.name});
    } catch (e) {
      throw mapFirebaseError(e);
    }
  }
}
