import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show LiquidGlassWidgets;
import 'package:material_ui/material_ui.dart';

import 'core/errors/app_failure.dart' show NotFoundFailure, ValidationFailure;
import 'core/notifications/background_handler.dart';

import 'core/locale/app_locale.dart';
import 'core/security/inactivity_guard.dart';
import 'core/providers/notification_providers.dart';
import 'core/providers/service_providers.dart';
import 'core/router/app_navigation.dart'
    show navigateResetGlobal, rootNavigatorKey;
import 'core/router/app_router.dart';
import 'core/router/routes.dart' show Routes;
import 'core/services/app_services.dart';
import 'core/theme/theme_settings.dart';
import 'features/auth/providers/auth_providers.dart'
    show authRepositoryProvider, userProfileProvider;
import 'features/auth/providers/email_link_provider.dart';
import 'generated/app_localizations.dart';
import 'utils/themes/app_theme.dart';
import 'views/shared/app_snack_bar.dart' show showAppSnackBar;

/// Boot is intentionally tiny: [AppServices.init] owns every service, this
/// widget only wires Riverpod state (auth/router/theme/locale) into the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await AppServices.init();
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      brightnessResolver: (context) => Theme.of(context).brightness,
      child: ProviderScope(
        overrides: [
          themeSettingsProvider.overrideWithValue(AppServices.themeSettings),
        ],
        child: const TarlanBankApp(),
      ),
    ),
  );
}

/// Text for data-only FCM messages. Notification-payload messages are shown by
/// the system tray, and their text comes from the server payload.
String? notificationBannerText(RemoteMessage message) {
  final title = message.data['title']?.toString();
  final body =
      message.data['body']?.toString() ?? message.data['message']?.toString();
  final parts = <String>[
    if (title != null && title.isNotEmpty) title,
    if (body != null && body.isNotEmpty && body != title) body,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class TarlanBankApp extends ConsumerStatefulWidget {
  const TarlanBankApp({super.key});

  @override
  ConsumerState<TarlanBankApp> createState() => _TarlanBankAppState();
}

class _TarlanBankAppState extends ConsumerState<TarlanBankApp> {
  ProviderSubscription<AsyncValue<Uri>>? _emailLinkSub;
  ProviderSubscription<AsyncValue<RemoteMessage>>? _notificationSub;
  ProviderSubscription? _profileSub;
  bool _recoveringProfile = false;

  @override
  void initState() {
    super.initState();
    // listenManual lives for the whole app lifetime and is not re-subscribed
    // on rebuild (kitaphub pattern).
    _emailLinkSub = ref.listenManual(emailLinkUriProvider, (previous, next) {
      final uri = next.value;
      if (uri != null) unawaited(handleEmailLink(ref, uri));
    });
    // Notification-payload messages already get a system notification; show
    // an in-app banner only for data-only messages (nothing else displays).
    _notificationSub = ref.listenManual(notificationMessageProvider, (
      previous,
      next,
    ) {
      final message = next.value;
      if (message == null || message.notification != null) return;
      final text = notificationBannerText(message);
      final context = rootNavigatorKey.currentContext;
      if (text == null || context == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    });
    // Corrupt profile data: wipe the local account/PIN and restart auth.
    _profileSub = ref.listenManual(userProfileProvider, (previous, next) {
      final error = next.error;
      // Only corrupt/missing profile records trigger the local wipe; an
      // offline Firestore read must not delete a valid PIN.
      if (_recoveringProfile ||
          error == null ||
          (error is! ValidationFailure && error is! NotFoundFailure)) {
        return;
      }
      _recoveringProfile = true;
      unawaited(_recoverFromBadUserData());
    });
  }

  Future<void> _recoverFromBadUserData() async {
    try {
      await ref.read(userDataRecoveryProvider).call();
      await ref.read(authRepositoryProvider).logout();
      await navigateResetGlobal(Routes.login);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = rootNavigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        final l = AppLocalizations.of(context);
        showAppSnackBar(
          context,
          title: l.errorGeneric,
          message: l.dataRecoveryMessage,
          fromTop: true,
        );
      });
    } catch (error) {
      debugPrint('Profile recovery failed: $error');
    } finally {
      if (mounted) _recoveringProfile = false;
    }
  }

  @override
  void dispose() {
    _profileSub?.close();
    _emailLinkSub?.close();
    _notificationSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Token registration/unregistration follows the full-user auth state.
    ref.watch(notificationAuthBindingProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return InactivityGuard(
      child: MaterialApp.router(
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        locale: ref.watch(localeProvider),
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) return null;
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) return supported;
          }
          return supportedLocales.first;
        },
        // material_ui owns MaterialLocalizations; Flutter's global delegate is
        // a different (deprecated in 3.50) type — never mix them.
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
