import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sensitive action that was interrupted by Firebase's requires-recent-login.
/// The reauth screen performs it after the session has been confirmed.
enum PendingReauthAction { deleteAccount }

class PendingReauthActionNotifier extends Notifier<PendingReauthAction?> {
  @override
  PendingReauthAction? build() => null;

  void request(PendingReauthAction action) => state = action;

  void clear() => state = null;
}

final pendingReauthActionProvider =
    NotifierProvider<PendingReauthActionNotifier, PendingReauthAction?>(
      PendingReauthActionNotifier.new,
    );
