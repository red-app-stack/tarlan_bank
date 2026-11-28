import 'package:cloud_firestore/cloud_firestore.dart';

enum CardStatus { active, blocked, expired }

/// A payment instrument linked to a debit account (`cards/{cardId}`).
///
/// Fixes the old model's mistakes:
///  - a card is NOT an account type; many cards may link to one account.
///  - NO CVV anywhere (PCI-DSS forbids storing it, even encrypted).
///  - NO full PAN: only last4. The linked account number is the routing key.
class BankCard {
  const BankCard({
    required this.id,
    required this.accountId,
    required this.ownerId,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.holderName,
    required this.status,
    this.label,
    this.createdAt,
  });

  final String id;

  /// Linked account number (accounts/{number}).
  final String accountId;

  /// Denormalized owner so security rules need no join.
  final String ownerId;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final String holderName;
  final CardStatus status;

  /// Optional user-facing label, e.g. "Virtual", "Salary".
  final String? label;
  final DateTime? createdAt;

  bool get isUsable => status == CardStatus.active;

  Map<String, dynamic> toMap() => {
    'accountId': accountId,
    'ownerId': ownerId,
    'last4': last4,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'holderName': holderName,
    'status': status.name,
    if (label != null) 'label': label,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };

  factory BankCard.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Card document ${doc.id} has no data');
    }
    return BankCard.fromMap(doc.id, data);
  }

  /// Pure map parsing (unit-testable without a Firebase app).
  factory BankCard.fromMap(String id, Map<String, dynamic> data) {
    return BankCard(
      id: id,
      accountId: data['accountId'] as String,
      ownerId: data['ownerId'] as String,
      last4: data['last4'] as String,
      expiryMonth: (data['expiryMonth'] as num).toInt(),
      expiryYear: (data['expiryYear'] as num).toInt(),
      holderName: data['holderName'] as String,
      status: CardStatus.values.byName(data['status'] as String),
      label: data['label'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
