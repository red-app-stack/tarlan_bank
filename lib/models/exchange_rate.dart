class ExchangeRate {
  final double rate;
  final DateTime lastUpdated;

  ExchangeRate({required this.rate, required this.lastUpdated});

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    final num rawRate = json['rate'];
    return ExchangeRate(
      rate: rawRate.toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
