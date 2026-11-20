class AccountModel {
  final int id;
  final String accountNumber;
  final String accountType;
  final String currency;
  final double balance;
  final String status;
  final String fullName;
  final String phoneNumber;
  final int? expiryMonth;
  final int? expiryYear;
  final String? cvv;

  AccountModel({
    required this.id,
    required this.accountNumber,
    required this.accountType,
    required this.currency,
    required this.balance,
    required this.status,
    required this.fullName,
    required this.phoneNumber,
    required this.expiryMonth,
    required this.expiryYear,
    this.cvv,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      accountNumber: json['account_number'],
      accountType: json['account_type'],
      currency: json['currency'],
      balance: double.parse(json['balance'].toString()),
      status: json['status'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      expiryMonth: int.tryParse(json['expiry_month'].toString()),
      expiryYear: int.tryParse(json['expiry_year'].toString()),
      cvv: json['cvv']?.toString(),
    );
  }
}
