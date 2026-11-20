import 'package:tarlan_bank/services/interceptors.dart';
import 'package:tarlan_bank/services/server_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioManager {
  final Server server;
  final FlutterSecureStorage secureStorage;
  late final Dio _dio;

  DioManager({
    required this.server,
    required this.secureStorage,
  }) {
    _dio = Dio()
      ..options.sendTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.headers = {
        'bypass-tunnel-reminder': '1',
      }
      ..interceptors.addAll([
        RequestIdInterceptor(),
        AuthInterceptor(secureStorage: secureStorage),
      ]);
  }

  Future<void> _ensureBaseUrl() async {
    final url = await server.getBaseUrl();
    if (_dio.options.baseUrl != url) {
      _dio.options.baseUrl = url;
    }
  }

  bool _isRetryable(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final statusCode = e.response?.statusCode;
    return statusCode != null && statusCode >= 500 && statusCode < 600;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _makeRequest(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _makeRequest(
      () => _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _makeRequest(
      () => _dio.delete<T>(path,
          data: data, queryParameters: queryParameters, options: options),
    );
  }

  Future<ResponseBody> postStream(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureBaseUrl();

    try {
      final response = await _dio.post<ResponseBody>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {'Accept': 'text/event-stream'},
          responseType: ResponseType.stream,
        ),
      );
      server.recordSuccess();
      return response.data!;
    } on DioException catch (e) {
      // ❌ 4xx errors: Fail immediately
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        server.recordFailure();
        rethrow;
      }

      // ✅ 5xx/network errors: Retry once
      if (_isRetryable(e)) {
        print("🔄 Retrying postStream after network/5xx error...");
        await Future.delayed(const Duration(milliseconds: 800));
        await _ensureBaseUrl();

        try {
          final response = await _dio.post<ResponseBody>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: Options(
              headers: {'Accept': 'text/event-stream'},
              responseType: ResponseType.stream,
            ),
          );
          server.recordSuccess();
          return response.data!;
        } catch (e) {
          server.recordFailure();
          rethrow;
        }
      }

      server.recordFailure();
      rethrow;
    }
  }

  Future<Response<T>> _makeRequest<T>(
    Future<Response<T>> Function() request,
  ) async {
    await _ensureBaseUrl();
    try {
      final response = await request();
      server.recordSuccess();
      return response;
    } on DioException catch (e) {
      // ❌ 4xx: Fail immediately
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        server.recordFailure();
        rethrow;
      }

      // ✅ 5xx/Network: Use RetryHelper
      if (_isRetryable(e)) {
        return RetryHelper(this).retryRequest(request, e);
      }

      server.recordFailure();
      rethrow;
    }
  }
}

class RetryHelper {
  final DioManager manager;
  static const int maxRetries = 3;

  RetryHelper(this.manager);

  Future<Response<T>> retryRequest<T>(
    Future<Response<T>> Function() request,
    DioException initialException,
  ) async {
    int attempt = 0;
    DioException? lastError;

    while (attempt < maxRetries) {
      attempt++;
      print("🔄 Retry attempt $attempt/$maxRetries...");

      await Future.delayed(const Duration(milliseconds: 800));
      await manager._ensureBaseUrl();

      try {
        final response = await request();
        manager.server.recordSuccess();
        return response;
      } on DioException catch (e) {
        lastError = e;
        manager.server.recordFailure();

        if (!manager._isRetryable(e) || attempt == maxRetries) {
          rethrow;
        }
      }
    }

    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Max retries exceeded',
        );
  }
}
