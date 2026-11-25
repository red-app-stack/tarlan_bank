import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarlan_bank/core/locale/app_locale.dart';
import 'package:tarlan_bank/core/services/app_services.dart';
import 'package:tarlan_bank/features/auth/providers/auth_providers.dart';
import 'package:tarlan_bank/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => AppServices.notificationService,
);

/// Foreground FCM messages, including data-only payloads.
final notificationMessageProvider = StreamProvider<RemoteMessage>(
  (ref) => ref.watch(notificationServiceProvider).messages,
);

/// Single notificationTap seam the router consumes. Bumped by foreground,
/// background and terminated taps alike; the pending message is retrieved with
/// [NotificationService.consumePendingTap].
final notificationTapProvider = Provider<ValueNotifier<int>>(
  (ref) => ref.watch(notificationServiceProvider).tapEvent,
);

/// Full (non-anonymous) uid only — guests and signed-out users get null.
final _fullUidProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isAnonymous) return null;
  return user.uid;
});

/// Auth-driven token sync. Watched once from the app widget so registration
/// follows every full login and unregistration follows every logout.
final notificationAuthBindingProvider = Provider<bool>((ref) {
  final language = ref.watch(localeProvider).languageCode;
  ref.listen<String?>(_fullUidProvider, (previous, next) {
    if (previous == next) return;
    final service = ref.read(notificationServiceProvider);
    if (next != null) {
      unawaited(service.startForUser(next, language: language));
    } else if (previous != null) {
      unawaited(service.stop());
    }
  });

  ref.listen(localeProvider, (previous, next) {
    final service = ref.read(notificationServiceProvider);
    unawaited(service.refreshLanguage(next.languageCode));
  });

  // The auth stream may already hold a user when this provider is first read.
  final initial = ref.read(_fullUidProvider);
  if (initial != null) {
    unawaited(ref.read(notificationServiceProvider).startForUser(initial));
  }
  return true;
});
