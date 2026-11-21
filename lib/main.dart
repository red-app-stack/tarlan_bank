import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/locale/app_locale.dart';
import 'core/providers/service_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/app_services.dart';
import 'core/theme/theme_settings.dart';
import 'features/auth/providers/email_link_provider.dart';
import 'generated/app_localizations.dart';
import 'utils/themes/app_theme.dart';

/// Boot is intentionally tiny: [AppServices.init] owns every service, this
/// widget only wires Riverpod state (auth/router/theme/locale) into the app.
Future<void> main() async {
  await AppServices.init();
  runApp(
    ProviderScope(
      overrides: [
        themeSettingsProvider.overrideWithValue(AppServices.themeSettings),
      ],
      child: const TarlanBankApp(),
    ),
  );
}

class TarlanBankApp extends ConsumerStatefulWidget {
  const TarlanBankApp({super.key});

  @override
  ConsumerState<TarlanBankApp> createState() => _TarlanBankAppState();
}

class _TarlanBankAppState extends ConsumerState<TarlanBankApp> {
  ProviderSubscription<AsyncValue<Uri>>? _emailLinkSub;

  @override
  void initState() {
    super.initState();
    // listenManual lives for the whole app lifetime and is not re-subscribed
    // on rebuild (kitaphub pattern).
    _emailLinkSub = ref.listenManual(emailLinkUriProvider, (previous, next) {
      final uri = next.value;
      if (uri != null) unawaited(handleEmailLink(ref, uri));
    });
  }

  @override
  void dispose() {
    _emailLinkSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
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
    );
  }
}
