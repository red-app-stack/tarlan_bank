import 'dart:async';
import 'dart:convert';
import 'package:tarlan_bank/services/dio_manager.dart';
import 'package:dio/dio.dart' show DioException;
import '../services/secure_store.dart';
import 'package:crypto/crypto.dart';

class VerificationService {
  final DioManager _dio;
  final SecureStore _secureStore;

  Timer? _timer;
  int countdown = 60;

  final _countdownController = StreamController<int>.broadcast();
  Stream<int> get countdownStream => _countdownController.stream;

  VerificationService(
      {required DioManager dio, required SecureStore secureStore})
      : _secureStore = secureStore,
        _dio = dio;

  Future<void> sendCode(String email) async {
    final resp =
        await _dio.post('/auth/send-verification-code', data: {'email': email});
    if (resp.statusCode != 200) {
      throw DioException(requestOptions: resp.requestOptions);
    }
  }

  Future<Map<String, dynamic>> verifyRemoteCode(
    String code,
    String email,
    bool exists,
  ) async {
    try {
      final response = await _dio.post('/auth/verify-code', data: {
        'code': code,
        'email': email,
        'exists': exists,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return e.response?.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  Future<void> storeHashedCode(String code) async {
    final hash = _hash(code);
    await _secureStore.write('access_code', hash);
  }

  Future<bool> verifyAccessCode(String code) async {
    final storedHash = await _secureStore.read('access_code');
    if (storedHash == null) return false;
    return storedHash == _hash(code);
  }

  Future<bool> accessCodeExists() async {
    return await _secureStore.read('access_code') != null;
  }

  String _hash(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void startCountdown() {
    countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      _countdownController.add(countdown);
      if (countdown <= 0) t.cancel();
    });
  }

  void cancelCountdown() => _timer?.cancel();

  Future<void> clear() async {
    await _secureStore.delete('access_code');
    cancelCountdown();
  }
}
