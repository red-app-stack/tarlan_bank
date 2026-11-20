import 'dart:async';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/history_base.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

class TransferHistoryController extends GetxController {
  void refreshData(GlobalKey<RefreshIndicatorState> refreshKey) {
    print('Starting refresh delay...');
    Future.delayed(const Duration(seconds: 5), () {
      print('Delay complete, showing refresh indicator');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        refreshKey.currentState?.show();
        print('Refresh indicator shown');
      });
    });
  }

  final HistoryBaseController history = Get.put(HistoryBaseController());
  TransferHistoryController();

  @override
  void onInit() async {
    super.onInit();
    history.updatePeriod('За неделю');
    await history.loadAndCategorize(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now());
  }

  // void updatePeriod(String period) {
  //   selectedPeriod.value = period;
  //   final now = DateTime.now();
  //   DateTime? startDate;
  //   DateTime? endDate = now;
  //   String formatDate(DateTime date) {
  //     const months = [
  //       'января',
  //       'февраля',
  //       'марта',
  //       'апреля',
  //       'мая',
  //       'июня',
  //       'июля',
  //       'августа',
  //       'сентября',
  //       'октября',
  //       'ноября',
  //       'декабря'
  //     ];
  //     String yearSuffix =
  //         date.year != now.year ? " '${date.year.toString().substring(2)}" : "";
  //     return "${date.day} ${months[date.month - 1]}$yearSuffix";
  //   }
  //   switch (selectedPeriod.value) {
  //     case 'За неделю':
  //       startDate = now.subtract(const Duration(days: 7));
  //       break;
  //     case 'За месяц':
  //       startDate = now.subtract(const Duration(days: 30));
  //       break;
  //     case 'За 3 месяца':
  //       startDate = now.subtract(const Duration(days: 90));
  //       break;
  //     case 'Выбранный период':
  //       if (selectedDateRange.value != null) {
  //         startDate = selectedDateRange.value!.start;
  //         endDate = selectedDateRange.value!.end
  //             .add(Duration(days: 1))
  //             .subtract(Duration(microseconds: 1));
  //         print(endDate);
  //       }
  //       break;
  //   }
  //   if (startDate != null) {
  //     selectedPeriodDetail.value = startDate.day == endDate.day
  //         ? formatDate(startDate)
  //         : "${formatDate(startDate)} - ${formatDate(endDate)}";
  //   }
  //   loadTransactions(startDate, endDate);
  // }
}

class TransferHistoryScreen extends StatelessWidget {
  final controller = Get.put(TransferHistoryController());

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  TransferHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    controller.refreshData(_refreshIndicatorKey);
    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: FrostedAppBar(
          floating: true,
          leading: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/ic_back.svg',
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              }),
          title: Text(
            'История переводов',
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 20),
          ),
        ),
        body: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
            key: _refreshIndicatorKey,
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
                      start = controller.history.selectedDateRange.value!.start;
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 56 + kToolbarHeight),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    spacing: 16,
                    children: [
                      SizedBox(),
                      buildFilterCard(
                        context,
                        controller.history.selectedPeriodDetail,
                        () =>
                            showFilterBottomSheet(context, controller.history),
                      ),
                      Obx(() => controller.history.accountsController
                              .transactionHistory.isNotEmpty
                          ? _buildTransactionsList(context)
                          : buildEmptyState(
                              theme,
                              size,
                              'Здесь будет отображаться \nистория ваших переводов',
                            )),
                    ],
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
      final transactions =
          controller.history.categorizedTransactions[categories[0]] ?? [];

      Map<String, List<Transaction>> transactionsByDate = {};
      DateTime now = DateTime.now();
      for (var transaction in transactions) {
        String dateKey = (transaction.createdAt.year == now.year)
            ? DateFormat('d MMMM', 'ru').format(transaction.createdAt)
            : DateFormat('d MMMM y', 'ru').format(transaction.createdAt);
        transactionsByDate.putIfAbsent(dateKey, () => []);
        transactionsByDate[dateKey]!.add(transaction);
      }

      final today = DateFormat('d MMMM', 'ru').format(now);
      return transactions.isEmpty
          ? Center(
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
                  )))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactionsByDate.length,
              itemBuilder: (context, index) {
                String date = transactionsByDate.keys.elementAt(index);
                List<Transaction> dayTransactions = transactionsByDate[date]!;

                return CustomCard(
                  label: date == today ? 'Сегодня, $date' : date,
                  labelStyle: Theme.of(context).textTheme.titleLarge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      ...dayTransactions.map((transaction) =>
                          _buildTransactionContent(context, transaction)),
                    ],
                  ),
                );
              },
            );
    });
  }

  Widget _buildTransactionContent(
      BuildContext context, Transaction transaction) {
    return InkWell(
        onTap: () {
          Get.toNamed('/transferDetails', arguments: transaction);
        },
        splashColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        highlightColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: TransactionCard(tx: transaction));
  }
}
