import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';
import 'package:tarlan_bank/features/transactions/providers/transfer_ui_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/history_base.dart';

import 'package:tarlan_bank/features/transactions/widgets/transfer_header.dart';

class TransferHistoryScreen extends ConsumerStatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  ConsumerState<TransferHistoryScreen> createState() =>
      _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends ConsumerState<TransferHistoryScreen> {
  final GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();
  late final HistoryBaseController history;

  @override
  void initState() {
    super.initState();
    history = HistoryBaseController(
      ref,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    history.updatePeriod(periodWeek);
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    try {
      await history.loadAndCategorize(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    } on Object {
      // Keep the previous (possibly empty) state; no raw error is shown.
    }
  }

  Future<void> _onRefresh() async {
    final now = DateTime.now();
    DateTime? start;
    switch (history.selectedPeriod) {
      case periodWeek:
        start = now.subtract(const Duration(days: 7));
      case periodMonth:
        start = now.subtract(const Duration(days: 30));
      case periodThreeMonths:
        start = now.subtract(const Duration(days: 90));
      case periodCustom:
        start = history.selectedDateRange?.start;
    }
    try {
      await history.loadAndCategorize(start: start, end: now);
    } on Object {
      // Swallow only for UI resilience; cached list stays visible.
    }
  }

  void _openDetails(BankTransaction tx) {
    ref.read(selectedTransactionProvider.notifier).select(tx);
    context.go(Routes.transfersDetails);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final transactions = history.visibleTransactions;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: buildTransferHeader(context, l.transferHistory),
      body: RefreshIndicator(
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        key: refreshKey,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 56 + kToolbarHeight,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                spacing: 16,
                children: [
                  const SizedBox(),
                  buildFilterCard(
                    context,
                    history.selectedPeriodDetail,
                    () => showFilterBottomSheet(context, history),
                  ),
                  transactions.isEmpty
                      ? buildEmptyState(theme, size, l.noTransfers)
                      : _buildTransactionsList(context, l, transactions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    AppLocalizations l,
    List<BankTransaction> transactions,
  ) {
    final size = MediaQuery.of(context).size;
    final now = DateTime.now();
    final Map<String, List<BankTransaction>> byDate = {};

    for (final tx in transactions) {
      final created = tx.createdAt ?? now;
      final key = created.year == now.year
          ? DateFormat('d MMMM', 'ru').format(created)
          : DateFormat('d MMMM y', 'ru').format(created);
      byDate.putIfAbsent(key, () => []).add(tx);
    }

    if (byDate.isEmpty) {
      return Center(
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
          ),
        ),
      );
    }

    final today = DateFormat('d MMMM', 'ru').format(now);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: byDate.length,
      itemBuilder: (context, index) {
        final date = byDate.keys.elementAt(index);
        final dayTransactions = byDate[date]!;
        return CustomCard(
          label: date == today ? l.today(date) : date,
          labelStyle: Theme.of(context).textTheme.titleLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              ...dayTransactions.map(
                (tx) => _buildTransactionContent(context, tx),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionContent(BuildContext context, BankTransaction tx) {
    return InkWell(
      onTap: () => _openDetails(tx),
      splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      highlightColor: Theme.of(context).colorScheme.primary
          .withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TransactionCard(tx: tx),
    );
  }
}
