import 'dart:async';

import 'package:tarlan_bank/views/shared/history_base.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class PaymentHistoryController extends GetxController {
  final HistoryBaseController history = Get.put(HistoryBaseController());
  PaymentHistoryController();

  @override
  void onInit() async {
    super.onInit();
    history.updatePeriod('За неделю');
    await history.loadAndCategorize(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now());
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  final controller = Get.put(PaymentHistoryController());

  PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: buildHeader(context, 'История платежей'),
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
            bottom: false,
            top: false,
            child: RefreshIndicator(
              edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
              onRefresh: () async {
                try {
                  DateTime now = DateTime.now();
                  DateTime? start;
                  switch (controller.history.selectedPeriod.value) {
                    case 'За неделю':
                      start = now.subtract(const Duration(days: 7));
                      break;
                    case 'За месяц':
                      start = now.subtract(const Duration(days: 30));
                      break;
                    case 'За 3 месяца':
                      start = now.subtract(const Duration(days: 90));
                      break;
                    case 'Выбранный период':
                      if (controller.history.selectedDateRange.value != null) {
                        start =
                            controller.history.selectedDateRange.value!.start;
                      }
                      break;
                  }

                  await controller.history
                      .loadAndCategorize(start: start, end: now);
                  await Future.delayed(const Duration(milliseconds: 500));
                } on TimeoutException {
                  print('Refresh operation timed out');
                } catch (e) {
                  print('Error during refresh: $e');
                }
                return Future.value();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 56 + kToolbarHeight),
                    child: Column(
                      children: [
                        buildFilterCard(
                          context,
                          controller.history.selectedPeriodDetail,
                          () => showFilterBottomSheet(
                              context, controller.history),
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => controller.history.accountsController
                                  .paymentHistory.isNotEmpty
                              ? _buildTransactionsList(context)
                              : buildEmptyState(
                                  theme,
                                  size,
                                  'Здесь будет отображаться \nистория ваших платежей',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )));
  }

  Widget _buildTransactionsList(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Obx(() {
      final categories =
          controller.history.categorizedTransactions.keys.toList();
      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final transactions =
              controller.history.categorizedTransactions[category] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              transactions.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        final transaction = transactions[i];
                        return TransactionCard(
                          tx: transaction,
                        );
                      },
                    )
                  : Center(
                      child: Padding(
                          padding: EdgeInsets.all(size.height * 0.03),
                          child: SvgPicture.asset(
                            'assets/icons/ic_empty_list.svg',
                            height: size.width > size.height
                                ? size.height * 0.3
                                : size.width * 0.3,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.secondaryContainer,
                              BlendMode.srcIn,
                            ),
                          ))),
            ],
          );
        },
      );
    });
  }
}
