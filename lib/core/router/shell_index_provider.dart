import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the shell tab in sync with programmatic navigation (e.g. after a
/// create-account flow). Mirrors kitaphub's shell_index_provider.
class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 2; // Home tab

  void setIndex(int index) => state = index;
}

final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(
  ShellIndexNotifier.new,
);

/// One-shot target tab request from auth/create-account flows, replacing the
/// old AuthStateService targetRoute stream.
class PendingShellTabNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String tab) => state = tab;
  void clear() => state = null;
}

final pendingShellTabProvider =
    NotifierProvider<PendingShellTabNotifier, String?>(
      PendingShellTabNotifier.new,
    );
