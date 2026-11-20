import 'dart:async';
import 'package:tarlan_bank/services/dio_manager.dart';
import 'package:dio/dio.dart';

class LLMService {
  final DioManager dioManager;

  LLMService({required this.dioManager});

  Future<List<String>> getModels() async {
    try {
      final response = await dioManager.get('/api/models');

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['data'] as List).map((e) => e['id'] as String).toList();
      }
      throw Exception('Ошибка загрузки моделей: ${response.statusCode}');
    } catch (e) {
      throw Exception(
          'Не удалось подключиться к серверу. Техническая ошибка: $e');
    }
  }

  Future<ResponseBody> chatCompletion({
    required Map<String, dynamic> message,
    String sessionId = '',
    bool enableSearch = false,
  }) async {
    return await dioManager.postStream(
      '/api/chat',
      data: {
        'message': message,
        'sessionId': sessionId,
        'enableSearch': enableSearch,
      },
    );
  }
}
