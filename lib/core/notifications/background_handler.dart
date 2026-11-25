import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';

/// FCM requires a top-level, entry-point handler for messages received while
/// the app is in the background or terminated. Notification-payload messages
/// are displayed by the Android SDK even before this runs; the handler exists
/// so data payloads are not dropped.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  dev.log('[FCM] background message: ${message.messageId}');
}
