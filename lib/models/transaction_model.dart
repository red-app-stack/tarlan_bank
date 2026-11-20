import 'package:intl/intl.dart';

class Transaction {
  final int id;
  final String reference;
  final String fromAccount;
  final String fromAccountType;
  final String toAccount;
  final String toAccountType;
  final double amount;
  final String currency;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? fromUserName;
  final String? fromUserPicture;
  final String? fromUserRole;
  final String? fromUserPhone;
  final String? toUserName;
  final String? toUserPicture;
  final String? toUserRole;
  final String? toUserPhone;
  final String formattedCreatedAt;
  final String message;

  Transaction({
    required this.id,
    required this.reference,
    required this.fromAccount,
    required this.fromAccountType,
    required this.toAccount,
    required this.toAccountType,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.fromUserName,
    this.fromUserPicture,
    this.fromUserRole,
    this.fromUserPhone,
    this.toUserName,
    this.toUserPicture,
    this.toUserRole,
    this.toUserPhone,
    required this.formattedCreatedAt,
    required this.message,
  });

  static Transaction fromJson(Map<String, dynamic> json) {
    final DateTime rawCreatedAtUTC =
        DateTime.parse(json['created_at']).toLocal();
    final DateTime localCreatedAt = rawCreatedAtUTC;
    return Transaction(
      id: json['id'],
      reference: json['transaction_reference'],
      // Use null-aware operators to provide defaults if keys are missing or null
      fromAccount: json['from_account_number']?.toString() ?? '',
      fromAccountType: json['from_account_type']?.toString() ?? '',
      toAccount: json['to_account_number']?.toString() ?? '',
      toAccountType: json['to_account_type']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ??
          0.0, // Safer parsing
      currency: json['currency']?.toString() ?? '',
      type: json['transaction_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      createdAt: localCreatedAt, // Safer DateTime
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
              ?.toLocal() // Тоже конвертируем
          : null,
      // These are nullable in your model definition, so just assigning is fine:
      fromUserName: json['from_user_name'],
      fromUserPicture: json['from_user_picture'],
      fromUserRole: json['from_user_role'],
      fromUserPhone: json['from_user_phone_number'],
      toUserName: json['to_user_name'],
      toUserPicture: json['to_user_picture'],
      toUserRole: json['to_user_role'],
      toUserPhone: json['to_user_phone_number'],
      formattedCreatedAt: DateFormat(
        'dd.MM.yyyy HH:mm:ss',
      ).format(localCreatedAt), // Используем локальное время
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_reference': reference,
      'from_account_number': fromAccount,
      'from_account_type': fromAccountType,
      'to_account_number': toAccount,
      'to_account_type': toAccountType,
      'amount': amount,
      'currency': currency,
      'transaction_type': type,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'from_user_name': fromUserName,
      'from_user_picture': fromUserPicture,
      'from_user_role': fromUserRole,
      'from_user_phone_number': fromUserPhone,
      'to_user_name': toUserName,
      'to_user_picture': toUserPicture,
      'to_user_role': toUserRole,
      'to_user_phone_number': toUserPhone,
      'message': message,
    };
  }
}
