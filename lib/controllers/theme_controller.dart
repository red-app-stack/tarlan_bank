import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../services/secure_store.dart';
import '../views/shared/user_settings.dart';

class ThemeController extends GetxController {
  final secureStore = Get.find<SecureStore>();
  var themeMode = ThemeMode.system.obs;
  var isLoaded = false.obs;

  Future<void> loadSavedSettings() async {
    final settings = await secureStore.loadSettings();
    if (settings != null) {
      themeMode.value = settings.themeMode;
    } else {
      themeMode.value = ThemeMode.system;
    }
    isLoaded.value = true;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    saveThemeSettings();
  }

  Future<void> saveThemeSettings() async {
    final currentSettings =
        await secureStore.loadSettings() ?? UserSettings.defaults();
    final updatedSettings = currentSettings.copyWith(
      themeMode: themeMode.value,
    );
    await secureStore.saveSettings(updatedSettings);
  }

  void toggleTheme(BuildContext context) {
    setThemeMode(
      themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
