import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';

/// Ledger transaction types. [wireName] is the exact string stored in
/// Firestore and whitelisted by `firestore.rules`.
enum TransactionType {
  deposit('deposit'),
  withdrawal('withdrawal'),
  phoneTransfer('phone_transfer'),
  qrTransfer('qr_transfer'),
  currencyConversion('currency_conversion'),
  internalTransfer('internal_transfer'),
  cardTransfer('card_transfer'),
  swiftTransfer('swift_transfer');

  const TransactionType(this.wireName);
  final String wireName;

  static TransactionType fromWire(String value) => values.firstWhere(
    (t) => t.wireName == value,
    orElse: () => throw ValidationFailure('Unknown transaction type: $value'),
  );
}

enum TransactionStatus { pending, completed, failed, reversed }

/// A committed entry in the single Firestore ledger (`transactions/{txId}`).
///
/// Replaces the REST-shaped `models/transaction_model.dart` for the new
/// backend (same remodel as D8 did for accounts): doc ID is a client UUID
/// (create-only rules → idempotent), parties are nullable because `deposit`
/// has no sender and `withdrawal` no recipient, and owner IDs are denormalized
/// so history reads need no joins. The ledger is IMMUTABLE — a reversal is a
/// new compensating entry through the trusted path, never an edit.
class BankTransaction {
  const BankTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.fromAccountId,
    this.toAccountId,
    this.fromOwnerId,
    this.toOwnerId,
    this.createdAt,
    this.message,
    this.toCurrency,
    this.convertedAmount,
    this.rate,
    this.idempotencyKey,
  });

  /// Client-generated UUID v4; also the Firestore document ID.
  final String id;
  final String? fromAccountId;
  final String? toAccountId;
  final String? fromOwnerId;
  final String? toOwnerId;
  final double amount;
  final String currency;
  final TransactionType type;
  final TransactionStatus status;

  /// Null while a serverTimestamp write is still pending locally.
  final DateTime? createdAt;
  final String? message;
  final String? toCurrency;
  final double? convertedAmount;
  final double? rate;
  final String? idempotencyKey;

  /// Display string in local time (matches the legacy UI format).
  String get formattedCreatedAt => createdAt == null
      ? ''
      : DateFormat('dd.MM.yyyy HH:mm:ss').format(createdAt!.toLocal());

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'currency': currency,
    'type': type.wireName,
    'status': status.name,
    if (fromAccountId != null) 'fromAccountId': fromAccountId,
    if (toAccountId != null) 'toAccountId': toAccountId,
    if (fromOwnerId != null) 'fromOwnerId': fromOwnerId,
    if (toOwnerId != null) 'toOwnerId': toOwnerId,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (message != null && message!.isNotEmpty) 'message': message,
    if (toCurrency != null) 'toCurrency': toCurrency,
    if (convertedAmount != null) 'convertedAmount': convertedAmount,
    if (rate != null) 'rate': rate,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };

  factory BankTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Transaction document ${doc.id} has no data');
    }
    return BankTransaction.fromMap(doc.id, data);
  }

  /// Pure map parsing (unit-testable without a Firebase app).
  factory BankTransaction.fromMap(String id, Map<String, dynamic> data) {
    return BankTransaction(
      id: id,
      fromAccountId: data['fromAccountId'] as String?,
      toAccountId: data['toAccountId'] as String?,
      fromOwnerId: data['fromOwnerId'] as String?,
      toOwnerId: data['toOwnerId'] as String?,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      type: TransactionType.fromWire(data['type'] as String),
      status: TransactionStatus.values.byName(data['status'] as String),
      createdAt: _date(data['createdAt']),
      message: data['message'] as String?,
      toCurrency: data['toCurrency'] as String?,
      convertedAmount: _number(data['convertedAmount']),
      rate: _number(data['rate']),
      idempotencyKey: data['idempotencyKey'] as String?,
    );
  }

  factory BankTransaction.fromApiMap(Map<String, dynamic> data) =>
      BankTransaction.fromMap(
        (data['id'] ?? data['idempotencyKey']) as String,
        data,
      );
}

DateTime? _date(Object? value) => switch (value) {
  Timestamp t => t.toDate(),
  DateTime d => d,
  String s => DateTime.tryParse(s)?.toUtc(),
  _ => null,
};

double? _number(Object? value) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};
