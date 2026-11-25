import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'
    show ValueNotifier, debugPrint, defaultTargetPlatform, kIsWeb;

import 'package:tarlan_bank/services/dio_manager.dart';

/// Client-side FCM plumbing: permission, token sync with our server, and the
/// message/tap streams the UI and router consume. Every plugin/network call is
/// guarded — a missing server or a denied permission must never break startup.
class NotificationService {
  NotificationService({required this.messaging, required this.dio});

  final FirebaseMessaging messaging;
  final DioManager dio;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Foreground messages (notification and/or data payload).
  final StreamController<RemoteMessage> _messages =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messages => _messages.stream;

  /// Single notificationTap seam the router listens to. The value is an
  /// incrementing counter so two taps on the same message still navigate.
  final ValueNotifier<int> tapEvent = ValueNotifier<int>(0);
  RemoteMessage? _pendingTap;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _configured = false;

  /// Set only for a full (non-anonymous) session; cleared on logout.
  String? _activeUid;
  String? _lastKnownToken;
  String? _registeredToken;
  String? _registeredUid;
  Future<void>? _registrationInFlight;

  /// Called once from AppServices.init, after Firebase and Dio are ready.
  Future<void> initialize() async {
    if (_configured) return;
    _configured = true;
    await _setupLocalNotifications();
    try {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('FCM foreground options unavailable: $error');
    }
    try {
      // Background tap (app alive but in background).
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(handleTap);
      // Foreground message: presentation options above show the system
      // notification; the stream lets the UI show an in-app banner too.
      FirebaseMessaging.onMessage.listen(
        (message) async {
          debugPrint('[FCM] foreground message: ${message.messageId}');
          await _showLocalNotification(message);
          if (!_messages.isClosed) _messages.add(message);
        },
        onError: (Object error) {
          debugPrint('FCM foreground message error: $error');
        },
      );
      // Terminated-app tap is delivered exactly once through this future.
      final initial = await messaging.getInitialMessage();
      if (initial != null) handleTap(initial);
      // The server sends via FCM multicast registration tokens; the newer
      // register()/FID API yields a different identifier, so keep this one.
      // ignore: deprecated_member_use
      _tokenRefreshSub = messaging.onTokenRefresh.listen(_onTokenRefreshed);
    } catch (error) {
      debugPrint('FCM listener setup failed: $error');
    }
  }

  /// Records a tap from any lifecycle state. The router consumes the pending
  /// message via [consumePendingTap] once the navigator is available.
  void handleTap(RemoteMessage message) {
    _pendingTap = message;
    tapEvent.value++;
  }

  RemoteMessage? consumePendingTap() {
    final message = _pendingTap;
    _pendingTap = null;
    return message;
  }

  Future<void> _setupLocalNotifications() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null) return;
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            handleTap(RemoteMessage(data: data));
          } catch (error) {
            debugPrint('[FCM] bad notification payload: $error');
          }
        },
      );
      const channel = AndroidNotificationChannel(
        'tarlan_general',
        'Tarlan Bank',
        description: 'Transfers, payments and security notices',
        importance: Importance.high,
        playSound: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (error) {
      debugPrint('[FCM] local notification setup failed: $error');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Tarlan Bank';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    try {
      await _local.show(
        id:
            message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'tarlan_general',
            'Tarlan Bank',
            channelDescription: 'Transfers, payments and security notices',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error) {
      debugPrint('[FCM] local notification show failed: $error');
    }
  }

  /// Called by the auth binding for every newly signed-in full user.
  Future<void> startForUser(String uid) async {
    if (uid.isEmpty) return;
    _activeUid = uid;
    if (_registeredUid == uid && _registeredToken != null) return;
    await _requestPermissionSafely();
    await _registerCurrentToken(uid);
  }

  /// Called on logout/guest transition: drops our server-side registration.
  Future<void> stop() async {
    _activeUid = null;
    final token = _lastKnownToken ?? _registeredToken;
    _registeredToken = null;
    _registeredUid = null;
    _lastKnownToken = null;
    if (token == null || token.isEmpty) return;
    try {
      await dio.delete('/api/notifications/token', data: {'token': token});
    } catch (error) {
      debugPrint('FCM token unregister failed: $error');
    }
  }

  Future<void> _requestPermissionSafely() async {
    try {
      final settings = await messaging.requestPermission();
      debugPrint(
        '[FCM] permission=${settings.authorizationStatus} '
        'alert=${settings.alert} badge=${settings.badge} sound=${settings.sound}',
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          '[FCM] notifications denied in system settings — '
          'no push will be shown until the user enables them',
        );
      }
    } catch (error) {
      debugPrint('FCM permission request failed: $error');
    }
  }

  Future<void> _registerCurrentToken(String uid) async {
    if (_activeUid != uid) return;
    final pending = _registrationInFlight;
    if (pending != null) {
      await pending;
      if (_activeUid != uid) return;
      if (_registeredUid == uid && _registeredToken != null) return;
    }
    final task = _readAndRegister(uid);
    _registrationInFlight = task;
    try {
      await task;
    } finally {
      if (identical(_registrationInFlight, task)) _registrationInFlight = null;
    }
  }

  Future<void> _readAndRegister(String uid) async {
    try {
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _postToken(token: token, uid: uid);
    } catch (error) {
      debugPrint('FCM token read failed: $error');
    }
  }

  void _onTokenRefreshed(String token) {
    final uid = _activeUid;
    if (uid == null || uid.isEmpty) return;
    unawaited(_postToken(token: token, uid: uid));
  }

  Future<void> _postToken({required String token, required String uid}) async {
    _lastKnownToken = token;
    if (_activeUid != uid) return;
    if (_registeredUid == uid && _registeredToken == token) return;
    try {
      await dio.post(
        '/api/notifications/token',
        data: {'token': token, 'platform': _platform},
      );
      // The user may have logged out while the request was in flight.
      if (_activeUid != uid) return;
      _registeredToken = token;
      _registeredUid = uid;
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  String get _platform => kIsWeb ? 'web' : defaultTargetPlatform.name;

  void dispose() {
    _tokenRefreshSub?.cancel();
    _openedAppSub?.cancel();
    tapEvent.dispose();
    _messages.close();
  }
}
