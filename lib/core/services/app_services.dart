import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/theme/theme_settings.dart';
import 'package:tarlan_bank/firebase_options.dart';
import 'package:tarlan_bank/services/auth_service.dart';
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/dio_manager.dart';
import 'package:tarlan_bank/services/screen_protect_service.dart';
import 'package:tarlan_bank/services/secure_store.dart';
import 'package:tarlan_bank/services/server_service.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:tarlan_bank/services/verification_service.dart';
import 'package:tarlan_bank/utils/overlay_helper.dart';

/// Bootstrap owner: one place that creates/configures every long-lived
/// service. main() stays tiny and Riverpod providers in service_providers.dart
/// are the only way the app reads them. No service-locator registration.
class AppServices {
  AppServices._();

  static final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  static late final Server server;
  static late final DioManager dioManager;
  static late final SecureStore secureStore;
  static late final AuthStateService authStateService;
  static late final UserRepository userRepository;
  static late final AuthService authService;
  static late final VerificationService verificationService;
  static late final ThemeSettings themeSettings;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    server = Server();
    dioManager = DioManager(server: server, secureStorage: secureStorage);
    secureStore = SecureStore(secureStorage);
    authStateService = AuthStateService();
    userRepository = UserRepository(secureStore: secureStore);
    authService = AuthService(
      dio: dioManager,
      secureStore: secureStore,
      state: authStateService,
      userRepo: userRepository,
    );
    verificationService = VerificationService(
      dio: dioManager,
      secureStore: secureStore,
    );
    themeSettings = ThemeSettings(secureStore);
    await themeSettings.load();

    await _setupScreenProtection();
    OverlayHelper();
  }

  static Future<void> _setupScreenProtection() async {
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
}
