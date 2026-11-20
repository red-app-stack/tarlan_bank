import 'package:tarlan_bank/models/exchange_rate.dart';
import 'package:get/get.dart';
import '../services/dio_manager.dart';
import '../services/secure_store.dart';

class PublicServerController extends GetxController {
  DioManager dio = Get.find();
  final SecureStore secureStore = Get.find<SecureStore>();

  RxBool isLoading = false.obs;
  final Rx<Map<String, Map<String, ExchangeRate>>> exchangeRates =
      Rx<Map<String, Map<String, ExchangeRate>>>({});
  PublicServerController();

  Future<void> fetchExchangeRates() async {
    isLoading.value = true;
    try {
      final response = await dio.get('/exchange/rates');
      print('GOT RESPONSE FROM EXCHANGE: ${response.statusCode}');
      print(response.data);

      if (response.statusCode == 200) {
        final Map<String, Map<String, ExchangeRate>> rates = {};
        (response.data as Map<String, dynamic>)
            .forEach((fromCurrency, toCurrencies) {
          rates[fromCurrency] = {};
          (toCurrencies as Map<String, dynamic>)
              .forEach((toCurrency, rateData) {
            rates[fromCurrency]![toCurrency] = ExchangeRate.fromJson(rateData);
          });
        });
        exchangeRates.value = rates;
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
