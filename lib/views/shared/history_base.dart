// lib/views/shared/history_common.dart
import 'package:tarlan_bank/controllers/accounts_controller.dart';
import 'package:tarlan_bank/models/transaction_model.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

/// ──────────────────────────────────────────────
/// 1️⃣  Shared controller logic
/// ──────────────────────────────────────────────
class HistoryBaseController extends GetxController {
  final AccountsController accountsController = Get.find<AccountsController>();
  Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);

  // common Rx fields ---------------------------------------------------------
  RxString selectedPeriod = 'За неделю'.obs;
  RxString selectedPeriodDetail = ''.obs;

  RxMap<String, List<Transaction>> categorizedTransactions =
      <String, List<Transaction>>{'': []}.obs;

  // ──────────────────────────────────────────────
  // 2️⃣  Period handling helpers
  // ──────────────────────────────────────────────
  void updatePeriod(String period) {
    selectedPeriod.value = period;
    _updateSelectedDetail();
  }

  /// Formats the "from‑to" string that is shown on the filter card.
  void _updateSelectedDetail() {
    final now = DateTime.now();
    DateTime? start, end = now;

    switch (selectedPeriod.value) {
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
        // `selectedDateRange` lives in the TransferHistoryController.
        // If you need it here, expose it via a callback or a shared model.
        break;
    }

    if (start != null) {
      selectedPeriodDetail.value =
          '${_formatDate(start)} - ${_formatDate(end)}';
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    final yearSuffix = d.year != DateTime.now().year
        ? " '${d.year.toString().substring(2)}"
        : '';
    return "${d.day} ${months[d.month - 1]}$yearSuffix";
  }

  // ──────────────────────────────────────────────
  // 3️⃣  Load & categorize transactions (shared)
  // ──────────────────────────────────────────────
  Future<void> loadAndCategorize({DateTime? start, DateTime? end}) async {
    List<Transaction> newTxs = await accountsController.fetchTransactionHistory(
        startDate: start?.toIso8601String(), endDate: end?.toIso8601String());

    // Filter out internal transfers / deposits etc. – same rules as transfer screen
    newTxs = newTxs.where((tx) {
      return tx.type != 'internal_transfer' &&
          tx.fromUserName != tx.toUserName &&
          tx.type != 'currency_conversion' &&
          !(tx.type == 'deposit' && tx.amount == 1000.0);
    }).toList();

    // Merge with existing data (deduplication logic)
    final List<Transaction> all = [
      ...(accountsController.transactionHistory),
      ...newTxs
    ];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    accountsController.transactionHistory.value = List<Transaction>.from(all);
    accountsController.paymentHistory.value = List<Transaction>.from(all)
        .where(
          (element) => element.type == 'payment',
        )
        .toList();
    _categorize(all);
  }

  void _categorize(List<Transaction> txs) {
    final now = DateTime.now();
    Map<String, List<Transaction>> map = {};

    // Build categories based on the *currently selected* period
    switch (selectedPeriod.value) {
      case 'За неделю':
        map['На этой неделе'] = txs
            .where((t) =>
                t.createdAt.isAfter(now.subtract(const Duration(days: 7))))
            .toList();
        break;
      case 'За месяц':
        map['Этот месяц'] = txs
            .where((t) => t.createdAt.isAfter(DateTime(now.year, now.month)))
            .toList();
        break;
      case 'За 3 месяца':
        map['На этой неделе'] = // you can choose a different label
            txs
                .where((t) =>
                    t.createdAt.isAfter(now.subtract(const Duration(days: 90))))
                .toList();
        break;
      default:
        map['Ранее'] = txs.where((t) => !txs.contains(t)).toList(); // fallback
    }

    categorizedTransactions.value = map;
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction tx;
  const TransactionCard({required this.tx, super.key});

  String getTypeText(String type) {
    switch (type) {
      case 'deposit':
        return 'Вклад';
      case 'withdrawal':
        return 'Вывод';
      case 'phone_transfer':
        return 'Перевод по номеру';
      case 'qr_transfer':
        return 'QR перевод';
      case 'currency_conversion':
        return 'Обмен валюты';
      case 'internal_transfer':
        return 'Внутренний перевод';
      case 'card_transfer':
        return 'Перевод на карту';
      case 'swift_transfer':
        return 'SWIFT перевод';
      default:
        return 'Перевод';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(getTypeText(tx.type),
                style: Theme.of(context).textTheme.titleMedium),
            Text(formatCurrency(tx.amount, tx.currency, Get.locale.toString()),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: _getStatusColor(tx.status))),
          ]),
          const SizedBox(height: 8),
          // From / To

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if ((tx.fromUserName != null || tx.fromAccount.isNotEmpty) &&
                tx.type == 'qr_transfer')
              Text('От: ${tx.fromUserName ?? tx.fromAccount}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (tx.type == 'phone_transfer')
              Text('+7 ${formatPhone(tx.toUserPhone ?? '')}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (tx.type == 'card_transfer')
              Text(censorCardNumber(tx.toAccount),
                  style: Theme.of(context).textTheme.bodySmall),
            if (tx.type == 'card_transfer' ||
                tx.type == 'swift_transfer' ||
                tx.type == 'internal_transfer' ||
                tx.type == 'currency_conversion' ||
                tx.type == 'withdrawal' ||
                tx.type == 'deposit')
              Text(censorCardNumber(tx.toAccount),
                  style: Theme.of(context).textTheme.bodySmall),
            Text(
                DateFormat('HH:mm').format(
                    tx.createdAt.add(const Duration(hours: 5)).toLocal()),
                style: Theme.of(context).textTheme.bodySmall),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //   decoration: BoxDecoration(
            //       color: _getStatusColor(tx.status),
            //       borderRadius: BorderRadius.circular(12)),
            //   child: Text(_getStatusText(tx.status),
            //       style: Theme.of(context)
            //           .textTheme
            //           .bodySmall
            //           ?.copyWith(color: Colors.white)),
            // ),
          ]),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'reversed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getAmountColor(String status) {
    switch (status) {
      case 'to':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'from':
        return Colors.red;
      case 'reversed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'завершено';
      case 'pending':
        return 'в обработке';
      case 'failed':
        return 'ошибка';
      case 'reversed':
        return 'отменен';
      default:
        return 'в обработке';
    }
  }
}

Widget buildEmptyState(ThemeData theme, Size size, String message) {
  return Center(
    child: Column(
      children: [
        SizedBox(height: size.height * 0.15),
        SvgPicture.asset(
          'assets/icons/ic_empty_list.svg',
          height:
              size.width > size.height ? size.height * 0.3 : size.width * 0.3,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.secondaryContainer,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(height: size.height * 0.02),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        SizedBox(height: size.height * 0.02),
      ],
    ),
  );
}

Widget buildFilterCard(
    BuildContext context, RxString periodDetail, VoidCallback onTap) {
  final ThemeData theme = Theme.of(context);
  return SimpleCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashFactory: InkRipple.splashFactory,
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => Text(
                  periodDetail.value,
                  style: Theme.of(context).textTheme.titleMedium,
                )),
            SvgPicture.asset(
              'assets/icons/ic_filter.svg',
              width: 32,
              height: 32,
            ),
          ],
        ),
      ),
    ),
  );
}

void showFilterBottomSheet(
    BuildContext context, HistoryBaseController history) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Transform.rotate(
                    angle: -90 * 3.14159 / 180,
                    child: SvgPicture.asset(
                      'assets/icons/ic_back.svg',
                      width: 32,
                      height: 32,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    )),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Выберите период',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.start,
                    )),
              ),
              SizedBox(width: 48),
            ],
          ),
          SizedBox(height: 16),
          ...[
            'За неделю',
            'За месяц',
            'За 3 месяца',
            'Выбрать период в календаре'
          ].map((period) => ListTile(
                leading: Container(
                  height: theme.textTheme.titleMedium!.fontSize! * 2 + 8,
                  width: theme.textTheme.titleMedium!.fontSize! * 2 + 8,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    textAlign: TextAlign.center,
                    period == 'За неделю'
                        ? '7'
                        : period == 'За месяц'
                            ? '30'
                            : period == 'За 3 месяца'
                                ? '90'
                                : '∞',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                title: Text(period),
                onTap: () async {
                  if (period == 'Выбрать период в календаре') {
                    Navigator.pop(context);
                    await selectDateRange(context, history);
                  } else {
                    history.updatePeriod(period);
                    Navigator.pop(context);
                  }
                },
              )),
          SizedBox(height: 32),
        ],
      ),
    ),
  );
}

Future<void> selectDateRange(
    BuildContext context, HistoryBaseController history) async {
  final theme = Theme.of(context);
  DateTimeRange tempRange = history.selectedDateRange.value ??
      DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      );

  final picked = await showDialog<DateTimeRange>(
    context: context,
    builder: (BuildContext context) => Dialog(
      child: Container(
        height: 400,
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Выберите период',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfDateRangePicker(
                view: DateRangePickerView.month,
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: PickerDateRange(
                  tempRange.start,
                  tempRange.end,
                ),
                minDate: DateTime(2023),
                maxDate: DateTime.now(),
                monthViewSettings: DateRangePickerMonthViewSettings(
                  firstDayOfWeek: 1,
                  showTrailingAndLeadingDates: true,
                ),
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is PickerDateRange &&
                      args.value.startDate != null) {
                    tempRange = DateTimeRange(
                      start: args.value.startDate,
                      end: args.value.endDate ?? args.value.startDate,
                    );
                  }
                },
                headerStyle: DateRangePickerHeaderStyle(
                  backgroundColor: theme.colorScheme.surface,
                  textStyle: theme.textTheme.titleMedium,
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: theme.textTheme.bodyMedium,
                  todayTextStyle: theme.textTheme.bodyMedium,
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: theme.textTheme.bodyMedium,
                  todayTextStyle: theme.textTheme.bodyMedium,
                ),
                selectionColor: theme.colorScheme.primary,
                todayHighlightColor: theme.colorScheme.primary,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempRange);
                  },
                  child: Text(
                    'Выбрать',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (picked != null) {
    history.selectedDateRange.value = picked;
    history.updatePeriod('Выбранный период');
  }
}
