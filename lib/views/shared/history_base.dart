// lib/views/shared/history_base.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';
import 'package:tarlan_bank/features/transactions/providers/transactions_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/app_icons.dart';

/// Stable internal period keys (labels are localized by the UI).
const String periodWeek = 'week';
const String periodMonth = 'month';
const String periodThreeMonths = 'threeMonths';
const String periodCustom = 'custom';

/// Shared, GetX-free history state used by the transfer (and payment) screens.
/// It reads transactions through [transactionsRepositoryProvider] and reports
/// mutations through [onChanged] so an owning ConsumerState can call setState.
class HistoryBaseController {
  HistoryBaseController(this.ref, {this.onChanged});

  final WidgetRef ref;
  final VoidCallback? onChanged;

  DateTimeRange? selectedDateRange;
  String selectedPeriod = periodWeek;
  String selectedPeriodDetail = '';
  Map<String, List<BankTransaction>> categorizedTransactions = {'': []};

  void updatePeriod(String period) {
    selectedPeriod = period;
    _updateSelectedDetail();
    onChanged?.call();
  }

  /// Formats the "from - to" string shown on the filter card.
  void _updateSelectedDetail() {
    final now = DateTime.now();
    DateTime? start;
    final end = now;
    switch (selectedPeriod) {
      case periodWeek:
        start = now.subtract(const Duration(days: 7));
      case periodMonth:
        start = now.subtract(const Duration(days: 30));
      case periodThreeMonths:
        start = now.subtract(const Duration(days: 90));
      case periodCustom:
        start = selectedDateRange?.start;
    }
    if (start != null) {
      final endLabel = selectedPeriod == periodCustom
          ? (selectedDateRange?.end ?? now)
          : end;
      selectedPeriodDetail = '${_formatDate(start)} - ${_formatDate(endLabel)}';
    }
    onChanged?.call();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange = range;
    updatePeriod(periodCustom);
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
      'декабря',
    ];
    final yearSuffix = d.year != DateTime.now().year
        ? " '${d.year.toString().substring(2)}"
        : '';
    return "${d.day} ${months[d.month - 1]}$yearSuffix";
  }

  /// Loads & categorizes transactions (shared by both history screens).
  Future<void> loadAndCategorize({DateTime? start, DateTime? end}) async {
    final txs = await ref
        .read(transactionsRepositoryProvider)
        .fetchHistory(
          startDate: start?.toIso8601String(),
          endDate: end?.toIso8601String(),
        );

    // Same exclusion rules as the legacy screen (internal bookkeeping only).
    final filtered = txs.where((tx) {
      return tx.type != TransactionType.internalTransfer &&
          tx.type != TransactionType.currencyConversion;
    }).toList();

    _categorize(filtered);
  }

  void _categorize(List<BankTransaction> txs) {
    final now = DateTime.now();
    final map = <String, List<BankTransaction>>{};
    switch (selectedPeriod) {
      case periodWeek:
        map['week'] = txs
            .where(
              (t) =>
                  t.createdAt?.isAfter(now.subtract(const Duration(days: 7))) ??
                  false,
            )
            .toList();
      case periodMonth:
        map['month'] = txs
            .where(
              (t) =>
                  t.createdAt?.isAfter(DateTime(now.year, now.month)) ?? false,
            )
            .toList();
      case periodThreeMonths:
        map['threeMonths'] = txs
            .where(
              (t) =>
                  t.createdAt?.isAfter(
                    now.subtract(const Duration(days: 90)),
                  ) ??
                  false,
            )
            .toList();
      default:
        map['all'] = List<BankTransaction>.from(txs);
    }
    categorizedTransactions = map;
    onChanged?.call();
  }

  /// All currently visible transactions (first category), newest first.
  List<BankTransaction> get visibleTransactions {
    if (categorizedTransactions.isEmpty) return const [];
    final txs = categorizedTransactions.values.first;
    final sorted = List<BankTransaction>.from(txs);
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }
}

/// Localized label for a transaction type.
String transactionTypeLabel(AppLocalizations l, TransactionType type) =>
    switch (type) {
      TransactionType.deposit => l.typeDeposit,
      TransactionType.withdrawal => l.typeWithdrawal,
      TransactionType.phoneTransfer => l.typePhoneTransfer,
      TransactionType.qrTransfer => l.typeQrTransfer,
      TransactionType.currencyConversion => l.typeCurrencyConversion,
      TransactionType.internalTransfer => l.typeInternalTransfer,
      TransactionType.cardTransfer => l.typeCardTransfer,
      TransactionType.swiftTransfer => l.typeSwiftTransfer,
    };

class TransactionCard extends StatelessWidget {
  const TransactionCard({required this.tx, super.key});

  final BankTransaction tx;

  Color _statusColor(TransactionStatus status) => switch (status) {
    TransactionStatus.completed => Colors.green,
    TransactionStatus.pending => Colors.orange,
    TransactionStatus.failed => Colors.red,
    TransactionStatus.reversed => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transactionTypeLabel(l, tx.type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                formatCurrency(tx.amount, tx.currency, 'ru_RU'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: _statusColor(tx.status)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (tx.type == TransactionType.qrTransfer &&
                  tx.fromAccountId != null)
                Text(
                  '${l.from}: ${censorCardNumber(tx.fromAccountId!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else if (tx.type == TransactionType.phoneTransfer ||
                  tx.type == TransactionType.cardTransfer ||
                  tx.type == TransactionType.swiftTransfer ||
                  tx.type == TransactionType.deposit ||
                  tx.type == TransactionType.withdrawal)
                Text(
                  censorCardNumber(tx.toAccountId ?? ''),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (tx.message != null && tx.message!.isNotEmpty)
                Expanded(
                  child: Text(
                    tx.message!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Text(
                DateFormat('HH:mm').format(
                  (tx.createdAt ?? DateTime.now())
                      .add(const Duration(hours: 5))
                      .toLocal(),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget buildEmptyState(ThemeData theme, Size size, String message) {
  return Center(
    child: Column(
      children: [
        SizedBox(height: size.height * 0.15),
        SvgPicture.asset(
          AppIcons.emptyList,
          height: size.width > size.height
              ? size.height * 0.3
              : size.width * 0.3,
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
  BuildContext context,
  String periodDetail,
  VoidCallback onTap,
) {
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
            Text(periodDetail, style: Theme.of(context).textTheme.titleMedium),
            SvgPicture.asset(AppIcons.filter, width: 32, height: 32),
          ],
        ),
      ),
    ),
  );
}

void showFilterBottomSheet(
  BuildContext context,
  HistoryBaseController history,
) {
  final theme = Theme.of(context);
  final l = AppLocalizations.of(context);
  final periods = <String, String>{
    periodWeek: l.week,
    periodMonth: l.month,
    periodThreeMonths: l.threeMonths,
    periodCustom: l.calendarPeriod,
  };
  final icons = <String, String>{
    periodWeek: '7',
    periodMonth: '30',
    periodThreeMonths: '90',
    periodCustom: '∞',
  };

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Transform.rotate(
                  angle: -90 * 3.14159 / 180,
                  child: SvgPicture.asset(
                    AppIcons.back,
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l.selectPeriod,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          ...periods.entries.map(
            (entry) => ListTile(
              leading: Container(
                height: theme.textTheme.titleMedium!.fontSize! * 2 + 8,
                width: theme.textTheme.titleMedium!.fontSize! * 2 + 8,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  icons[entry.key]!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              title: Text(entry.value),
              onTap: () async {
                if (entry.key == periodCustom) {
                  context.pop();
                  await selectDateRange(context, history);
                } else {
                  history.updatePeriod(entry.key);
                  context.pop();
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

Future<void> selectDateRange(
  BuildContext context,
  HistoryBaseController history,
) async {
  final theme = Theme.of(context);
  final l = AppLocalizations.of(context);
  DateTimeRange tempRange =
      history.selectedDateRange ??
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
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
            Text(l.selectPeriod, style: theme.textTheme.titleLarge),
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
                monthViewSettings: const DateRangePickerMonthViewSettings(
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
                  onPressed: () => context.pop(),
                  child: Text(
                    l.cancel,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => context.pop(tempRange),
                  child: Text(
                    l.choose,
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
    history.setDateRange(picked);
  }
}
