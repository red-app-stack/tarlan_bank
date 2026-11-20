import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarlan_bank/core/router/app_router.dart';
import 'package:tarlan_bank/utils/themes/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Riverpod + go_router app shell (Week 1, ADDITIVE).
///
/// Not yet wired into `main.dart` — the current GetX `GetMaterialApp` keeps
/// running so nothing breaks. Switching `main.dart` to
/// `runApp(const TarlanBankApp())` is the final cutover step once features are
/// migrated. Import pattern mirrors `main.dart` (material_ui, not
/// flutter/material) to avoid the double ThemeData/ThemeMode conflict.
class TarlanBankApp extends StatelessWidget {
  const TarlanBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppView());
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Tarlan Bank',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
        Locale('kk', 'KZ'),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
