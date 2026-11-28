import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/history_base.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  late final HistoryBaseController _history;
  bool _ready = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _history = HistoryBaseController(
      ref,
      onChanged: () {
        if (_ready && mounted) setState(() {});
      },
    );
    _history.updatePeriod(periodWeek);
    _ready = true;
    _load();
  }

  DateTime? _startFor(String period) {
    final now = DateTime.now();
    return switch (period) {
      periodWeek => now.subtract(const Duration(days: 7)),
      periodMonth => now.subtract(const Duration(days: 30)),
      periodThreeMonths => now.subtract(const Duration(days: 90)),
      periodCustom => _history.selectedDateRange?.start,
      _ => now.subtract(const Duration(days: 7)),
    };
  }

  DateTime? _endFor(String period) =>
      period == periodCustom ? _history.selectedDateRange?.end : DateTime.now();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _history.loadAndCategorize(
        start: _startFor(_history.selectedPeriod),
        end: _endFor(_history.selectedPeriod),
      );
    } catch (_) {
      // Keep the last successful categorization visible (offline-friendly).
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  String _categoryLabel(String key, AppLocalizations l) => switch (key) {
    'week' => l.categoryThisWeek,
    'month' => l.categoryThisMonth,
    'threeMonths' => l.categoryThisWeek,
    _ => l.categoryEarlier,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: buildHeader(context, l.paymentHistory),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: screenPadding,
                child: Column(
                  children: [
                    buildFilterCard(
                      context,
                      _history.selectedPeriodDetail,
                      () => showFilterBottomSheet(context, _history),
                    ),
                    const SizedBox(height: 16),
                    if (_loading && _history.categorizedTransactions.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (_history.visibleTransactions.isEmpty)
                      buildEmptyState(theme, size, l.paymentHistoryEmpty)
                    else
                      _buildTransactionsList(theme, l),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme, AppLocalizations l) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.categorizedTransactions.length,
      itemBuilder: (context, index) {
        final entry = _history.categorizedTransactions.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _categoryLabel(entry.key, l),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            ...entry.value.map((tx) => TransactionCard(tx: tx)),
          ],
        );
      },
    );
  }
}
