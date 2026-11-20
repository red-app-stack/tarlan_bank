import 'package:tarlan_bank/services/secure_store.dart';
import 'package:tarlan_bank/utils/overlay_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'controllers/theme_controller.dart';
import 'services/dio_manager.dart';
import 'services/server_service.dart';
import 'utils/themes/app_theme.dart';
import 'routes/app_routes.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tarlan_bank/services/screen_protect_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/locale/app_locale.dart';
import 'generated/app_localizations.dart';

Future<void> main() async {
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final ss = FlutterSecureStorage();
  Get.put<Server>(Server(), permanent: true);
  Get.put<DioManager>(
    DioManager(server: Get.find(), secureStorage: ss),
    permanent: true,
  );
  Get.put<SecureStore>(SecureStore(ss), permanent: true);
  Get.put(ThemeController(), permanent: true);

  // ProviderScope wraps the legacy GetMaterialApp so migrated ConsumerWidgets
  // (login today, more screens tomorrow) work inside GetX routes. The app is
  // still Get-driven; switching to TarlanBankApp is the final cutover.
  runApp(const ProviderScope(child: MyApp()));

  await _setupScreenProtection();
  OverlayHelper();
}

Future<void> _setupScreenProtection() async {
  final secureStore = Get.find<SecureStore>();
  final settings = await secureStore.loadSettings();

  if (settings?.screenProtection == true) {
    await ScreenProtect.enable();
  } else {
    await ScreenProtect.disable();
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      // GetX 5's GetMaterialApp is material_ui-based (ThemeData/ThemeMode come
      // from material_ui), matching the rest of the app's type system. Routing
      // is wired internally via getPages + GetObserver; the old manual
      // navigatorKey/onGenerateRoute setup used Get.addPages and
      // PageRedirect.page(), which GetX 5 removed.
      () => GetMaterialApp(
        locale: ref.watch(localeProvider),
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) return null;
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) return supported;
          }
          return supportedLocales.first;
        },
        // material_ui owns MaterialLocalizations; Flutter's global delegate
        // is a different (deprecated in 3.50) type — never mix them.
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        initialRoute: Routes.main,
        getPages: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
