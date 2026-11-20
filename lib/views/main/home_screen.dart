import 'dart:async';

import 'package:tarlan_bank/controllers/public_server_controller.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/views/shared/currency_rates_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';
import '../shared/custom_card.dart';

class HomeScreenController extends GetxController {
  final List<ServiceItemData> homeServices = [
    ServiceItemData('assets/images/creditcard.png', 'Карты', 'card'),
    ServiceItemData('assets/images/deposit.png', 'Депозиты', 'deposit'),
    ServiceItemData('assets/images/credit.png', 'Кредиты', 'credit'),
    ServiceItemData('assets/images/installment.png', 'Рассрочка', 'transfer'),
    ServiceItemData(
        'assets/images/investments.png', 'Инвестиции', '/investments'),
  ];

  PublicServerController publicServerController =
      Get.put(PublicServerController());
  AuthStateService state = Get.find();
}

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeScreenController controller = Get.put(HomeScreenController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    if (controller.publicServerController.exchangeRates.value.isEmpty) {
      controller.publicServerController.fetchExchangeRates();
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          onRefresh: () async {
            try {
              await controller.publicServerController.fetchExchangeRates();
              await Future.delayed(const Duration(milliseconds: 500));
            } on TimeoutException {
              print('Refresh operation timed out');
            } catch (e) {
              print('Error during refresh: $e');
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 56 + kToolbarHeight),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomCard(
                    label: 'Главная',
                    padding: EdgeInsetsGeometry.all(18),
                  ),
                  CustomCard(
                      padding: EdgeInsets.all(0),
                      child: SizedBox(
                          height: 128,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.homeServices.length,
                            itemExtent: 100,
                            itemBuilder: (context, index) {
                              final service = controller.homeServices[index];
                              return ServiceItem(
                                imagePath: service.iconPath,
                                label: service.label,
                                iconSize: 120 * 0.6,
                                expanded: false,
                                onTap: () {
                                  service.routeArg == '/investments'
                                      ? Get.toNamed(service.routeArg)
                                      : {
                                          controller.state.setTargetArguments(
                                              {'extra': service.routeArg}),
                                          Get.toNamed('/createAccount')
                                        };
                                },
                              );
                            },
                          ))),
                  Obx(() {
                    return CustomCard(
                      label: 'Курс валют',
                      labelStyle: theme.textTheme.titleLarge,
                      child: CurrencyRatesCard(
                        exchangeRates: controller
                            .publicServerController.exchangeRates.value,
                        isLoading:
                            controller.publicServerController.isLoading.value,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
