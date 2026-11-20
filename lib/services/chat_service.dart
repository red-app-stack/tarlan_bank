// lib/features/chat/data/chat_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_manager.dart';

class ChatServiceException implements Exception {
  final int? statusCode;
  final String message;

  const ChatServiceException({this.statusCode, required this.message});

  @override
  String toString() => 'ChatServiceException($statusCode): $message';
}

class ChatService {
  final DioManager _dio;
  const ChatService({required DioManager dio}) : _dio = dio;

  Future<void> warmup() async {
    ResponseBody body;
    try {
      body = await _dio.postStream('/api/chat/warmup', data: {});
    } on DioException catch (e) {
      throw ChatServiceException(
        statusCode: e.response?.statusCode,
        message: _extractError(e),
      );
    }

    final completer = Completer<void>();

    final subscription = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (!line.startsWith('data: ')) return;
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty) return;

        Map<String, dynamic> event;
        try {
          event = json.decode(jsonStr) as Map<String, dynamic>;
        } catch (_) {
          return;
        }

        switch (event['type'] as String?) {
          case 'done':
            if (!completer.isCompleted) completer.complete();
          case 'error':
            final msg = (event['message'] as String?) ?? 'Warmup failed';
            if (!completer.isCompleted) {
              completer.completeError(ChatServiceException(message: msg));
            }
        }
      },
      onError: (Object err) {
        if (!completer.isCompleted) {
          completer.completeError(
            ChatServiceException(message: err.toString()),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    try {
      await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  Future<String> sendMessage({
    required String sessionId,
    required String message,
    void Function(String chunk)? onChunk,
  }) async {
    ResponseBody body;
    try {
      body = await _dio.postStream(
        '/api/chat',
        data: {'sessionId': sessionId, 'message': message},
      );
    } on DioException catch (e) {
      throw ChatServiceException(
        statusCode: e.response?.statusCode,
        message: _extractError(e),
      );
    }

    final completer = Completer<String>();
    final StringBuffer fullText = StringBuffer();

    final subscription = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (!line.startsWith('data: ')) return;
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty) return;

        Map<String, dynamic> event;
        try {
          event = json.decode(jsonStr) as Map<String, dynamic>;
        } catch (_) {
          return;
        }

        final type = event['type'] as String?;

        switch (type) {
          case 'chunk':
            final chunk = (event['text'] as String?) ?? '';
            if (chunk.isNotEmpty) {
              fullText.write(chunk);
              onChunk?.call(chunk);
            }

          case 'done':
            final finalText = (event['text'] as String?) ?? fullText.toString();
            if (!completer.isCompleted) {
              completer.complete(finalText.trim());
            }

          case 'error':
            final msg = (event['message'] as String?) ?? 'Unknown error';
            if (!completer.isCompleted) {
              completer.completeError(ChatServiceException(message: msg));
            }
        }
      },
      onError: (Object err) {
        if (!completer.isCompleted) {
          completer.completeError(
            ChatServiceException(message: err.toString()),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(fullText.toString().trim());
        }
      },
      cancelOnError: true,
    );

    try {
      return await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> clearSession(String sessionId) async {
    try {
      await _dio.delete<void>('/api/chat/$sessionId');
    } on DioException catch (e) {
      debugPrint('ChatService: clearSession failed — ${e.message}');
    }
  }

  String _extractError(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      return (body['error'] as String?) ?? e.message ?? 'Request failed';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'The assistant is taking too long. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your connection.';
    }
    return e.message ?? 'Request failed';
  }
}
