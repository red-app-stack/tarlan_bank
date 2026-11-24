import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tarlan_bank/services/interceptors.dart';
import 'package:tarlan_bank/services/server_service.dart';

/// Per-request timeouts. The chat endpoint streams a response that can take a
/// while to produce its first chunk, so it must not share the short standard
/// receive timeout (profile copied from kitaphub, where chat streaming works).
enum TimeoutProfile { standard, chat }

extension _TimeoutDurations on TimeoutProfile {
  Duration get connect => const Duration(seconds: 15);

  Duration get receive => switch (this) {
    TimeoutProfile.standard => const Duration(seconds: 15),
    TimeoutProfile.chat => const Duration(minutes: 1),
  };

  Duration get send => switch (this) {
    TimeoutProfile.standard => const Duration(seconds: 15),
    TimeoutProfile.chat => const Duration(minutes: 1),
  };
}

class DioManager {
  final Server server;
  final FlutterSecureStorage secureStorage;
  late final Dio _standard;
  late final Dio _chat;

  DioManager({required this.server, required this.secureStorage}) {
    _standard = _buildDio(TimeoutProfile.standard);
    _chat = _buildDio(TimeoutProfile.chat);
  }

  Dio _buildDio(TimeoutProfile profile) {
    return Dio()
      ..options.connectTimeout = profile.connect
      ..options.receiveTimeout = profile.receive
      ..options.sendTimeout = profile.send
      ..options.headers = {'bypass-tunnel-reminder': '1'}
      ..interceptors.addAll([
        RequestIdInterceptor(),
        AuthInterceptor(secureStorage: secureStorage),
      ]);
  }

  Dio _dioFor(TimeoutProfile profile) => switch (profile) {
    TimeoutProfile.standard => _standard,
    TimeoutProfile.chat => _chat,
  };

  Future<void> _ensureBaseUrl([
    TimeoutProfile profile = TimeoutProfile.standard,
  ]) async {
    final url = await server.getBaseUrl();
    final dio = _dioFor(profile);
    if (dio.options.baseUrl != url) {
      dio.options.baseUrl = url;
    }
  }

  /// Only connection/timeout failures are retried. A 5xx (or any other HTTP
  /// error) means the server *received* the request — retrying a money
  /// transfer or a chat message could duplicate it. Adopted from kitaphub's
  /// safer policy.
  bool _isRetryable(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    TimeoutProfile profile = TimeoutProfile.standard,
  }) {
    return _makeRequest(
      () =>
          _dioFor(profile)
              .get<T>(path, queryParameters: queryParameters, options: options),
      profile: profile,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    TimeoutProfile profile = TimeoutProfile.standard,
  }) {
    return _makeRequest(
      () => _dioFor(profile).post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      profile: profile,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    TimeoutProfile profile = TimeoutProfile.standard,
  }) {
    return _makeRequest(
      () => _dioFor(profile).delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      profile: profile,
    );
  }

  /// Streaming SSE endpoint. Uses the chat profile by default and shares the
  /// same retry helper as every other request instead of its own one-shot
  /// retry loop. Retries only happen before the response body is handed over,
  /// so a half-streamed reply is never replayed.
  Future<ResponseBody> postStream(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    TimeoutProfile profile = TimeoutProfile.chat,
  }) async {
    final response = await _makeRequest<ResponseBody>(
      () => _dioFor(profile).post<ResponseBody>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {'Accept': 'text/event-stream'},
          responseType: ResponseType.stream,
        ),
      ),
      profile: profile,
    );
    return response.data!;
  }

  Future<Response<T>> _makeRequest<T>(
    Future<Response<T>> Function() request, {
    TimeoutProfile profile = TimeoutProfile.standard,
  }) async {
    await _ensureBaseUrl(profile);

    try {
      final response = await request();
      server.recordSuccess();
      return response;
    } on DioException catch (e) {
      // HTTP errors already reached the server: never replay them.
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        server.recordFailure();
        rethrow;
      }

      if (_isRetryable(e)) {
        return RetryHelper(this, profile: profile).retryRequest(request, e);
      }

      server.recordFailure();
      rethrow;
    }
  }
}

class RetryHelper {
  final DioManager manager;
  final TimeoutProfile profile;

  static const int maxRetries = 3;

  RetryHelper(this.manager, {this.profile = TimeoutProfile.standard});

  Future<Response<T>> retryRequest<T>(
    Future<Response<T>> Function() request,
    DioException initialException,
  ) async {
    int attempt = 0;
    DioException? lastError;

    while (attempt < maxRetries) {
      attempt++;
      debugPrint('🔄 Retry attempt $attempt/$maxRetries…');
      await Future.delayed(const Duration(milliseconds: 800));
      await manager._ensureBaseUrl(profile);

      try {
        final response = await request();
        manager.server.recordSuccess();
        return response;
      } on DioException catch (e) {
        lastError = e;
        manager.server.recordFailure();
        if (!manager._isRetryable(e) || attempt == maxRetries) rethrow;
      }
    }

    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Max retries exceeded',
        );
  }
}
