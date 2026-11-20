import 'package:get/get.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  // ---- DI -------------------------------------------------------------
  final AuthService authService = Get.find<AuthService>();

  // ---- UI state -------------------------------------------------------
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs; // optional, used for snackbars

  // Input controllers are *not* part of this file – they live in the screen widget.
  // --------------------------------------------------------------------

  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      await authService.login(email: email, password: password);
      // Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = 'Login failed';
      rethrow; // let the UI decide how to show it
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    isLoading.value = true;
    try {
      await authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      // Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = 'Registration failed';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await authService.logout();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    isLoading.value = true;
    try {
      await authService.deleteUser();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Called on app start to decide if we can skip login screen
  Future<void> checkAuthStatus() async {
    final tokenExists =
        await authService.verifyToken(); // will also verify against server
  }
}
