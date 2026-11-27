import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI view model for the account/card details screen. Derived from the
/// Firestore [Account] ledger and card instruments; no CVV is ever stored.
class BankCard {
  const BankCard({
    required this.id,
    required this.accountNumber,
    required this.name,
    required this.cardType,
    required this.type,
    required this.number,
    required this.tengeBalance,
    required this.usdBalance,
    required this.euroBalance,
    required this.color,
    this.expiryDate = '12/30',
    this.cvv = '',
  });

  final int id;
  final String accountNumber;
  final String name;
  final String cardType;
  final String type;
  final String number;
  final String? tengeBalance;
  final String? usdBalance;
  final String? euroBalance;
  final String color;
  final String expiryDate;
  final String cvv;
}

/// Last card/account opened from any surface; read by CardDetailsScreen.
class SelectedCardNotifier extends Notifier<BankCard?> {
  @override
  BankCard? build() => null;

  void select(BankCard? card) => state = card;
}

final selectedCardProvider = NotifierProvider<SelectedCardNotifier, BankCard?>(
  SelectedCardNotifier.new,
);
