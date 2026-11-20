import 'package:dio/dio.dart'
    show Interceptor, RequestOptions, RequestInterceptorHandler;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;

  const AuthInterceptor({required this.secureStorage});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.read(key: 'auth_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Accept'] ??= 'application/json';
    options.headers['Content-Type'] ??= 'application/json';

    return handler.next(options);
  }
}

class RequestIdInterceptor extends Interceptor {
  static final Uuid _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['x-request-id'] ??= _uuid.v4();
    return handler.next(options);
  }
}
