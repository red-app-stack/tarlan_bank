// // src/models/card_model.dart (or wherever your CardModel lives)

// class AccountModel {
//   final int id;
//   final String accountNumber; // card_number in DB
//   final String accountType; // always 'card'
//   final String currency;
//   final double balance; // balance for this card
//   final String status;
//   final int expiryMonth; // changed to int
//   final int expiryYear; // changed to int
//   final String? cvv; // plain CVV – may be null
//   final String fullName; // NEW field
//   final String phoneNumber; // NEW field

//   AccountModel({
//     required this.id,
//     required this.accountNumber,
//     required this.accountType,
//     required this.currency,
//     required this.balance,
//     required this.status,
//     required this.expiryMonth,
//     required this.expiryYear,
//     this.cvv,
//     required this.fullName,
//     required this.phoneNumber,
//   });

//   factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
//         id: json['id'] as int,
//         accountNumber: json['card_number'] ?? json['account_number'],
//         accountType: json['account_type'] ?? 'card',
//         currency: json['currency'].toString(),
//         balance: (num.tryParse(json['balance'].toString()) ?? 0).toDouble(),
//         status: json['status'].toString(),
//         expiryMonth: int.parse(json['expiry_month'].toString()),
//         expiryYear: int.parse(json['expiry_year'].toString()),
//         cvv: json['cvv']?.toString(),
//         fullName: json['full_name'] ?? '',
//         phoneNumber: json['phone_number'] ?? '',
//       );
// }
