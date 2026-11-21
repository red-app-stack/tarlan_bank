import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/providers/service_providers.dart';

/// A saved transfer recipient. Kept deliberately small: the old REST
/// [Transaction] shape is not needed just to render the favourites list.
class FavoriteTransfer {
  const FavoriteTransfer({required this.name, required this.accountNumber});

  final String name;
  final String accountNumber;
}

/// Persisted favourites, read through the shared secure-store provider.
/// Malformed or legacy payloads degrade to an empty list instead of crashing.
final favoriteTransfersProvider = FutureProvider<List<FavoriteTransfer>>((
  ref,
) async {
  final raw = await ref.watch(secureStoreProvider).read('favorite_transfers');
  if (raw == null || raw.isEmpty) return const <FavoriteTransfer>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <FavoriteTransfer>[];
    return decoded.whereType<Map<String, dynamic>>().map((map) {
      return FavoriteTransfer(
        name:
            (map['toUserName'] ?? map['to_user_name'] ?? map['name'] ?? '')
                as String,
        accountNumber:
            (map['toAccount'] ??
                    map['to_account'] ??
                    map['accountNumber'] ??
                    '')
                as String,
      );
    }).toList();
  } catch (_) {
    return const <FavoriteTransfer>[];
  }
});
