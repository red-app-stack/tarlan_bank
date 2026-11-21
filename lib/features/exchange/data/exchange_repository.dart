import 'package:tarlan_bank/models/exchange_rate.dart';

abstract interface class ExchangeRepository {
  Future<List<ExchangeRate>> readRates();
  Stream<List<ExchangeRate>> watchRates();
}
