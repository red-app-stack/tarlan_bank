import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';
import 'package:tarlan_bank/core/router/routes.dart' show Routes;
import 'package:tarlan_bank/features/transactions/data/recipient_lookup.dart';
import 'package:tarlan_bank/features/transactions/data/transaction_model.dart';
import 'package:tarlan_bank/features/transactions/providers/transfer_ui_providers.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/formatters.dart';
import 'package:tarlan_bank/views/shared/history_base.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';
import 'package:tarlan_bank/views/shared/screen_padding.dart';

import 'package:tarlan_bank/features/transactions/widgets/lookup_identity_row.dart';
import 'package:tarlan_bank/features/transactions/widgets/transfer_header.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  const TransactionDetailsScreen({super.key, this.transaction});

  /// Optional prefill. When the router builds this screen with no arguments
  /// and no transaction was published, a friendly empty state is shown.
  final BankTransaction? transaction;

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  static const String favoritesKey = 'favorite_transfers';

  bool isFavorite = false;
  bool _checkedFavorite = false;
  String? _recipientForId;
  TransferRecipient? _recipient;
  bool _loadingRecipient = false;

  Future<void> _loadRecipient(BankTransaction tx) async {
    if (tx.toAccountId == null) return;
    final id = tx.id;
    if (_recipientForId == id) return;
    _recipientForId = id;
    if (mounted) setState(() => _loadingRecipient = true);
    try {
      final recipient = await ref
          .read(recipientRepositoryProvider)
          .lookupRecipient(accountNumber: tx.toAccountId);
      if (mounted && _recipientForId == id) {
        setState(() => _recipient = recipient);
      }
    } on Object {
      // Keep the masked account fallback.
    } finally {
      if (mounted && _recipientForId == id) {
        setState(() => _loadingRecipient = false);
      }
    }
  }

  BankTransaction? get _transaction =>
      widget.transaction ?? ref.watch(selectedTransactionProvider);

  Future<List<String>> _favoriteIds() async {
    final store = ref.read(secureStoreProvider);
    final raw = await store.read(favoritesKey);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } on Object {
      return const <String>[];
    }
  }

  Future<void> _writeFavoriteIds(List<String> ids) async {
    await ref.read(secureStoreProvider).write(favoritesKey, jsonEncode(ids));
  }

  Future<void> _loadFavoriteState(String id) async {
    final ids = await _favoriteIds();
    if (!mounted) return;
    setState(() {
      isFavorite = ids.contains(id);
      _checkedFavorite = true;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    final ids = await _favoriteIds();
    if (isFavorite) {
      ids.removeWhere((element) => element == id);
    } else if (!ids.contains(id)) {
      ids.add(id);
    }
    await _writeFavoriteIds(ids);
    if (mounted) setState(() => isFavorite = !isFavorite);
  }

  String _statusText(AppLocalizations l, BankTransaction tx) {
    final type = transactionTypeLabel(l, tx.type);
    return switch (tx.status) {
      TransactionStatus.completed => l.statusCompleted(type),
      TransactionStatus.pending => l.statusPending(type),
      TransactionStatus.failed => l.statusFailed(type),
      TransactionStatus.reversed => l.statusFailed(type),
    };
  }

  void _repeat(BankTransaction tx) {
    ref.read(selectedTransactionProvider.notifier).select(tx);
    final route = switch (tx.type) {
      TransactionType.phoneTransfer => Routes.transfersPhone,
      TransactionType.internalTransfer => Routes.transfersSelf,
      TransactionType.cardTransfer => Routes.transfersCard,
      TransactionType.currencyConversion => Routes.transfersConvert,
      TransactionType.qrTransfer => Routes.transfersQr,
      _ => Routes.transfers,
    };
    if (context.canPop()) context.pop();
    context.go(route);
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // HISTORY SCREEN BROKE.
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tx = _transaction;

    if (tx == null) {
      return Scaffold(
        appBar: buildTransferHeader(context, l.receipt),
        body: Center(
          child: Padding(
            padding: screenPadding,
            child: Text(
              l.noTransaction,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    if (!_checkedFavorite || _recipientForId != tx.id) {
      final transactionId = tx.id;
      final recipientTransaction = tx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_checkedFavorite) _loadFavoriteState(transactionId);
        _loadRecipient(recipientTransaction);
      });
    }

    return Scaffold(
      appBar: buildTransferHeader(context, l.receipt),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: screenPadding,
            child: Column(
              children: [
                Card(
                  shape: CustomBorder(),
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _statusText(l, tx),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          formatCurrency(
                                            tx.amount,
                                            tx.currency,
                                            'ru_RU',
                                          ),
                                          style: theme.textTheme.headlineLarge
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const CircleAvatar(
                                    radius: 20,
                                    backgroundImage: AssetImage(
                                      'assets/images/app_icon.png',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.recipient,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      LookupIdentityRow(
                                        phase: _loadingRecipient
                                            ? LookupPhase.loading
                                            : _recipient != null
                                            ? LookupPhase.found
                                            : LookupPhase.empty,
                                        fullName: _recipient?.fullName,
                                        initials: _recipient?.initials,
                                        fallbackText: censorCardNumber(
                                          tx.toAccountId ?? '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
                                  _buildDetailRow(
                                    theme,
                                    l.transactionType,
                                    transactionTypeLabel(l, tx.type),
                                  ),
                                  _buildDetailRow(
                                    theme,
                                    l.transactionId,
                                    tx.id,
                                  ),
                                  _buildDetailRow(
                                    theme,
                                    l.dateTime,
                                    tx.formattedCreatedAt,
                                  ),
                                  if (tx.convertedAmount != null)
                                    _buildDetailRow(
                                      theme,
                                      l.convertedAmount,
                                      formatCurrency(
                                        tx.convertedAmount!,
                                        tx.toCurrency ?? tx.currency,
                                        'ru_RU',
                                      ),
                                    ),
                                  if (tx.rate != null)
                                    _buildDetailRow(
                                      theme,
                                      l.exchangeRate,
                                      tx.rate!.toStringAsFixed(6),
                                    ),
                                  _buildDetailRow(
                                    theme,
                                    l.commission,
                                    '0 ${tx.currency}',
                                  ),
                                  _buildDetailRow(theme, l.sender, l.unknown),
                                  _buildDetailRow(
                                    theme,
                                    l.senderAccount,
                                    censorCardNumber(tx.fromAccountId ?? ''),
                                  ),
                                  if (tx.message != null &&
                                      tx.message!.isNotEmpty)
                                    _buildDetailRow(
                                      theme,
                                      l.message,
                                      tx.message!,
                                    ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SimpleCard(
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ServiceItem(
                            iconData: Icons.share,
                            label: l.share,
                            iconSize: 24,
                          ),
                          ServiceItem(
                            iconData: Icons.repeat,
                            label: l.repeat,
                            iconSize: 24,
                            onTap: () => _repeat(tx),
                          ),
                          ServiceItem(
                            iconData: Icons.cancel,
                            label: l.cancelTransfer,
                            iconSize: 24,
                          ),
                          ServiceItem(
                            iconData: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            label: isFavorite
                                ? l.removeFromFavorites
                                : l.addToFavorites,
                            iconSize: 24,
                            onTap: () => _toggleFavorite(tx.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    const double waveHeight = 6.0;
    const double waveWidth = 6.0;

    path.moveTo(rect.left, rect.top);
    var up = true;
    for (double x = rect.left; x < rect.right; x += waveWidth) {
      if (up) {
        path.relativeQuadraticBezierTo(
          waveWidth / 2,
          -waveHeight,
          waveWidth,
          0,
        );
      } else {
        path.relativeQuadraticBezierTo(waveWidth / 2, waveHeight, waveWidth, 0);
      }
      up = !up;
    }
    path.lineTo(rect.right, rect.bottom);
    up = true;
    for (double x = rect.right; x > rect.left; x -= waveWidth) {
      if (up) {
        path.relativeQuadraticBezierTo(
          -waveWidth / 2,
          waveHeight,
          -waveWidth,
          0,
        );
      } else {
        path.relativeQuadraticBezierTo(
          -waveWidth / 2,
          -waveHeight,
          -waveWidth,
          0,
        );
      }
      up = !up;
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
