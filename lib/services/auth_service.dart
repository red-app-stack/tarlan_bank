// services/auth_service.dart
import 'package:tarlan_bank/services/auth_state_service.dart';
import 'package:tarlan_bank/services/dio_manager.dart';
import 'package:tarlan_bank/services/user_repository.dart';
import 'package:dio/dio.dart' show Options, DioException;

import '../models/user_model.dart';
import 'secure_store.dart';

class AuthService {
  final DioManager dio;
  final SecureStore secureStore;
  final AuthStateService state;
  final UserRepository userRepo;
  AuthService({
    required this.dio,
    required this.secureStore,
    required this.state,
    required this.userRepo,
  });

  /// Login → returns token & user data
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    state.setChecking(true);
    final resp = await dio.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password.trim()},
    );
    if (resp.statusCode == 200) {
      await _storeCredentials(resp.data['token'], resp.data['user']);
      state.setAuthenticated(true);
      state.setChecking(false);
      return resp.data; // {token, user}
    } else {
      state.setAuthenticated(false);
      state.setChecking(false);
      throw DioException(requestOptions: resp.requestOptions);
    }
  }

  /// Register → same shape as login
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    state.setChecking(true);
    final resp = await dio.post(
      '/auth/register',
      data: {
        'email': email.trim(),
        'password': password.trim(),
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
      },
    );
    if (resp.statusCode == 201) {
      await _storeCredentials(resp.data['token'], resp.data['user']);
      state.setAuthenticated(true);
      state.setChecking(false);
      return resp.data;
    } else {
      state.setAuthenticated(false);
      state.setChecking(false);
      throw DioException(requestOptions: resp.requestOptions);
    }
  }

  /// Logout – server side
  Future<void> logout() async {
    state.setChecking(true);
    final token = await secureStore.read('auth_token');
    if (token != null) {
      await dio.post(
        '/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s! < 500,
        ),
      );
      await deleteToken();
      await userRepo.clearUser();
    }
    state.setIsLoggedIn(false);
    state.setAuthenticated(false);
    state.setChecking(false);
  }

  /// Delete user – server side
  Future<void> deleteUser() async {
    state.setChecking(true);
    final token = await secureStore.read('auth_token');
    if (token != null) {
      await dio.delete(
        '/auth/delete-user',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s! < 500,
        ),
      );
    }
    await userRepo.clearAll();
    state.setIsLoggedIn(false);
    state.setAuthenticated(false);
    state.setChecking(false);
  }

  /// Verify token against backend
  Future<bool> verifyToken() async {
    final token = await secureStore.read('auth_token');
    if (token == null) return false;
    try {
      state.setChecking(true);
      final resp = await dio.get(
        '/auth/verify',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final verified = resp.statusCode == 200;
      if (verified) {
        state.setAuthenticated(true);
        await userRepo.retrieveLocalUser();
      }
      state.setChecking(false);
      return verified;
    } catch (_) {
      state.setChecking(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> checkUserExistence({
    String? email,
    String? phoneNumber,
  }) async {
    state.setChecking(true);
    final resp = await dio.post(
      '/auth/check-user',
      data: {'email': ?email, 'phoneNumber': ?phoneNumber},
    );
    state.setChecking(false);
    return resp.data;
  }

  Future<bool> verifyPartialEmail({
    required String enteredEmail,
    required String obfuscatedEmail,
  }) async {
    state.setChecking(true);
    final resp = await dio.post(
      '/auth/check-partial-email',
      data: {'enteredEmail': enteredEmail, 'obfuscatedEmail': obfuscatedEmail},
    );
    state.setChecking(false);
    return resp.statusCode == 200;
  }

  Future<void> _storeCredentials(
    String token,
    Map<String, dynamic> userData,
  ) async {
    await secureStore.write('auth_token', token);
    final user = UserModel.fromJson(userData);
    await userRepo.storeUser(user);
  }

  Future<void> deleteToken() => secureStore.delete('auth_token');
}
