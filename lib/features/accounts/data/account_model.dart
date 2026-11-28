import 'package:cloud_firestore/cloud_firestore.dart';

/// Financial account products. `debit` is the spending account (the old
/// system mislabeled it 'card' — a card is an instrument, see [BankCard]).
enum AccountType { debit, deposit, credit }

enum AccountStatus { active, inactive, closed }

/// Term-deposit product parameters. The Node monthly job accrues interest
/// from these (Admin SDK, trusted); clients never compute interest.
class DepositTerms {
  const DepositTerms({
    required this.annualRate,
    required this.termMonths,
    required this.maturityAt,
    this.autoRenew = false,
  });

  /// Fraction per annum: 0.12 == 12% p.a. Monthly accrual = balance * rate/12.
  final double annualRate;
  final int termMonths;
  final DateTime maturityAt;
  final bool autoRenew;

  Map<String, dynamic> toMap() => {
    'annualRate': annualRate,
    'termMonths': termMonths,
    'maturityAt': Timestamp.fromDate(maturityAt),
    'autoRenew': autoRenew,
  };

  factory DepositTerms.fromMap(Map<String, dynamic> map) => DepositTerms(
    annualRate: (map['annualRate'] as num).toDouble(),
    termMonths: (map['termMonths'] as num).toInt(),
    maturityAt: (map['maturityAt'] as Timestamp).toDate(),
    autoRenew: map['autoRenew'] as bool? ?? false,
  );
}

/// Credit (loan) product parameters. `balance` on a credit account is the
/// OUTSTANDING DEBT (positive), not spendable money.
class CreditTerms {
  const CreditTerms({
    required this.creditLimit,
    required this.annualRate,
    required this.termMonths,
    this.nextPaymentAt,
  });

  final double creditLimit;

  /// Fraction per annum: 0.18 == 18% p.a.
  final double annualRate;
  final int termMonths;
  final DateTime? nextPaymentAt;

  Map<String, dynamic> toMap() => {
    'creditLimit': creditLimit,
    'annualRate': annualRate,
    'termMonths': termMonths,
    if (nextPaymentAt != null)
      'nextPaymentAt': Timestamp.fromDate(nextPaymentAt!),
  };

  factory CreditTerms.fromMap(Map<String, dynamic> map) => CreditTerms(
    creditLimit: (map['creditLimit'] as num).toDouble(),
    annualRate: (map['annualRate'] as num).toDouble(),
    termMonths: (map['termMonths'] as num).toInt(),
    nextPaymentAt: (map['nextPaymentAt'] as Timestamp?)?.toDate(),
  );
}

/// A financial account in the single Firestore ledger (`accounts/{number}`).
///
/// Balance semantics by product:
///  - debit/deposit: funds owned, >= 0.
///  - credit: outstanding debt, >= 0. Available = creditLimit - balance.
///    Repayment (debit -> credit transfer) decreases BOTH balances.
class Account {
  const Account({
    required this.number,
    required this.ownerId,
    required this.type,
    required this.currency,
    required this.balance,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.depositTerms,
    this.creditTerms,
    this.imagePath,
    this.hideBalance = false,
  });

  /// 16-digit account number; also the Firestore document ID (UNIQUE).
  final String number;
  final String ownerId;
  final AccountType type;
  final String currency;
  final double balance;
  final AccountStatus status;

  /// Null while a serverTimestamp write is still pending locally.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DepositTerms? depositTerms;
  final CreditTerms? creditTerms;

  /// Optional per-account artwork override for dashboard tiles. Falls back to
  /// a type-based accent image when absent (set by the user later).
  final String? imagePath;

  /// Per-account balance visibility on dashboard tiles.
  final bool hideBalance;

  /// Credit only: undrawn portion of the limit. Never spendable cash.
  double? get availableCredit =>
      (type == AccountType.credit && creditTerms != null)
      ? creditTerms!.creditLimit - balance
      : null;

  /// True when this account can be a transfer SOURCE. Credit accounts never
  /// are (drawing a loan is a disbursement, not a transfer).
  bool get isSpendable =>
      type != AccountType.credit && status == AccountStatus.active;

  Map<String, dynamic> toMap() => {
    'number': number,
    'ownerId': ownerId,
    'type': type.name,
    'currency': currency,
    'balance': balance,
    'status': status.name,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (depositTerms != null) 'terms': depositTerms!.toMap(),
    if (creditTerms != null) 'terms': creditTerms!.toMap(),
    if (imagePath != null) 'imagePath': imagePath,
    if (hideBalance) 'hideBalance': true,
  };

  factory Account.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Account document ${doc.id} has no data');
    }
    return Account.fromMap(doc.id, data);
  }

  /// Pure map parsing (unit-testable without a Firebase app).
  factory Account.fromMap(String number, Map<String, dynamic> data) {
    final type = AccountType.values.byName(data['type'] as String);
    final terms = data['terms'] as Map<String, dynamic>?;
    return Account(
      number: number,
      ownerId: data['ownerId'] as String,
      type: type,
      currency: data['currency'] as String,
      balance: (data['balance'] as num).toDouble(),
      status: AccountStatus.values.byName(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      depositTerms: type == AccountType.deposit && terms != null
          ? DepositTerms.fromMap(terms)
          : null,
      creditTerms: type == AccountType.credit && terms != null
          ? CreditTerms.fromMap(terms)
          : null,
      imagePath: data['imagePath'] as String?,
      hideBalance: data['hideBalance'] as bool? ?? false,
    );
  }
}
