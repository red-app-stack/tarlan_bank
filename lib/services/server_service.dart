import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Server {
  final dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10);

  String _currentBaseUrl = '';
  String get currentBaseUrl => _currentBaseUrl;
  Future<String>? _ongoingCheck;
  int _sequentialFailures = 0;
  static const int maxSequentialFailures = 3;

  void recordSuccess() {
    _sequentialFailures = 0;
  }

  void recordFailure() {
    if (kDebugMode) {
      print(_currentBaseUrl);
    }
    _sequentialFailures++;
    if (_sequentialFailures >= maxSequentialFailures) {
      print(
        "⚠️ $_sequentialFailures sequential errors, resetting _currentBaseUrl",
      );
      _currentBaseUrl = '';
      _sequentialFailures = 0;
    }
  }

  Future<String> getBaseUrl() async {
    if (_currentBaseUrl.isNotEmpty) {
      return _currentBaseUrl;
    }

    if (_ongoingCheck != null) {
      print("⏳ Another check is in progress, awaiting its result...");
      return await _ongoingCheck!;
    }

    _ongoingCheck = _performBaseUrlCheck();
    try {
      final result = await _ongoingCheck!;
      print("✅ Base URL check completed: $result");
      return result;
    } catch (e) {
      print("❌ Base URL check failed: $e");
      rethrow;
    } finally {
      // Clear the ongoing check when done (whether success or failure)
      print("🧹 Clearing ongoing check flag");
      _ongoingCheck = null;
    }
  }

  Future<String> _performBaseUrlCheck() async {
    final githubToken = dotenv.env['GITHUB_TOKEN'];
    final githubConfigApi = dotenv.env['CONFIG_API_URL'];
    final backupUrl = dotenv.env['API_URL_BACKUP'];

    if (githubToken == null || githubToken.isEmpty) {
      throw Exception("Missing GITHUB_TOKEN in .env");
    }
    if (githubConfigApi == null || githubConfigApi.isEmpty) {
      throw Exception("Missing CONFIG_API_URL in .env");
    }

    try {
      final tunnelUrl = await _fetchTunnelUrlFromGitHub(
        apiUrl: githubConfigApi,
        token: githubToken,
      );

      if (tunnelUrl == null || tunnelUrl.isEmpty) {
        throw Exception("GitHub config returned no tunnelUrl");
      }

      _currentBaseUrl = tunnelUrl;
      recordSuccess();
      print("🔄 GitHub tunnel URL fetched successfully: $_currentBaseUrl");
      return _currentBaseUrl;
    } catch (e) {
      print("⚠️ GitHub tunnel fetch failed: $e");
      recordFailure();

      if (backupUrl == null || backupUrl.isEmpty) {
        throw Exception("No fallback URL provided!");
      }

      print("🔄 Using fallback API_URL_BACKUP: $backupUrl");
      _currentBaseUrl = backupUrl;
      return _currentBaseUrl;
    }
  }

  Future<String?> _fetchTunnelUrlFromGitHub({
    required String apiUrl,
    required String token,
  }) async {
    final response = await dio.get(
      apiUrl,
      options: Options(
        headers: {
          // 'Authorization': 'Bearer $token',
          "Authorization": "token $token", // GitHub uses "token", not "Bearer"
          "Accept": "application/vnd.github+json",
        },
        validateStatus: (_) => true,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("GitHub returned status ${response.statusCode}");
    }

    final data = response.data;
    if (data == null) {
      throw Exception("GitHub API returned null data");
    }

    // For raw.githubusercontent.com, response.data is the raw file content
    // For api.github.com, it's a JSON object with a 'content' field
    String decodedJson;

    if (data is String) {
      // Direct raw content (from raw.githubusercontent.com)
      decodedJson = data;
    } else if (data is Map && data['content'] != null) {
      final dirtyBase64 = data['content'] as String;
      final cleanBase64 = dirtyBase64.replaceAll(RegExp(r'\s'), '');
      decodedJson = utf8.decode(base64Decode(cleanBase64));
    } else {
      throw Exception("Unexpected response format: ${data.runtimeType}");
    }

    print("📄 Decoded JSON: $decodedJson");
    final jsonMap = jsonDecode(decodedJson);

    // CRITICAL: Check if it's a Map before using string keys
    if (jsonMap is! Map<String, dynamic>) {
      throw Exception(
        "Expected JSON object, got ${jsonMap.runtimeType}. "
        "Content: ${jsonMap.toString().substring(0, 100)}...",
      );
    }

    if (!jsonMap.containsKey('tunnelUrl')) {
      throw Exception(
        "Missing 'tunnelUrl' key. Available keys: ${jsonMap.keys.toList()}",
      );
    }

    final tunnelUrl = '${jsonMap['tunnelUrl']}';
    print(tunnelUrl);
    return tunnelUrl;
  }
}
