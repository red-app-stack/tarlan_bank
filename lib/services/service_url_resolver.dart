import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tarlan_bank/core/config/service_urls.dart';

class ServiceUrlResolver {
  ServiceUrlResolver({
    Dio? dio,
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  }) : _dio = dio ?? Dio()
         ..options.connectTimeout = const Duration(seconds: 4)
         ..options.receiveTimeout = const Duration(seconds: 4),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences;

  static const _cacheKey = 'service_urls_cache';
  static const _firestoreTimeout = Duration(seconds: 5);

  final Dio _dio;
  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;

  Future<String> resolve() async {
    final configured = dotenv.env['BANK_API_URL']?.trim() ?? '';
    if (configured.isNotEmpty && await _reachable(configured)) {
      return _normalize(configured);
    }

    final cached = await _readCached();
    if (cached != null && await _reachable(cached.bankApiUrl)) {
      return cached.bankApiUrl;
    }

    try {
      final snap = await _firestore
          .collection('config')
          .doc('urls')
          .get()
          .timeout(_firestoreTimeout);
      final data = snap.data();
      if (data != null) {
        final urls = ServiceUrls.fromMap(data);
        await _writeCached(urls);
        return urls.bankApiUrl;
      }
    } catch (_) {}
    final cachedUrl = cached?.bankApiUrl;
    if (cachedUrl != null) return cachedUrl;
    if (configured.isNotEmpty) return _normalize(configured);
    throw StateError('No BANK_API_URL and config/urls is unavailable');
  }

  String _normalize(String url) => url.replaceAll(RegExp(r'/$'), '');

  Future<bool> _reachable(String baseUrl) async {
    try {
      final response = await _dio.get(
        '${baseUrl.replaceAll(RegExp(r'/$'), '')}/server-check',
        options: Options(
          validateStatus: (_) => true,
          headers: const {'bypass-tunnel-reminder': '1'},
        ),
      );
      return response.statusCode != null;
    } catch (_) {
      return false;
    }
  }

  Future<ServiceUrls?> _readCached() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return ServiceUrls.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCached(ServiceUrls urls) async {
    final prefs = await _prefs();
    await prefs.setString(_cacheKey, jsonEncode(urls.toJson()));
  }

  Future<SharedPreferences> _prefs() async {
    final existing = _preferences;
    if (existing != null) return existing;
    final created = await SharedPreferences.getInstance();
    _preferences = created;
    return created;
  }
}
