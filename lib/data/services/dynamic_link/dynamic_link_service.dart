import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'dynamic_link_models.dart';

/// Firesoft Redirection API hatası. [code] API'nin sabit hata kodudur
/// (`unauthorized`, `validation_error`, ...); ağ hatalarında `network`.
class DynamicLinkException implements Exception {
  const DynamicLinkException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'DynamicLinkException($code): $message';
}

/// Firesoft Redirection API v1 istemcisi.
///
/// API anahtarı `assets/config/secrets.json` dosyasından okunur (bu dosya
/// git'e girmez; şablonu `secrets.example.json`). Açılışta [loadSecrets]
/// çağrılmalıdır. `--dart-define` ile verilen değer dosyaya göre önceliklidir.
/// Not: Uygulamaya gömülen anahtar paketten çıkarılabilir.
class DynamicLinkService {
  DynamicLinkService._()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          // Hata gövdesini kendimiz okuyacağımız için durum kodu fırlatmasın.
          validateStatus: (_) => true,
        ),
      );

  static final DynamicLinkService instance = DynamicLinkService._();

  static const String _secretsAsset = 'assets/config/secrets.json';
  static const String _defaultBaseUrl =
      'https://redirection.firesoftyazilim.com';

  static String _baseUrl = const String.fromEnvironment(
    'FIRESOFT_REDIRECT_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static String _apiKey = const String.fromEnvironment(
    'FIRESOFT_REDIRECT_API_KEY',
  );

  static String get baseUrl => _baseUrl;

  /// Anahtar yoksa (dosya eksik ya da şablon değeri duruyorsa) özellik
  /// kullanılamaz.
  static bool get isConfigured =>
      _apiKey.startsWith('fsr_') && !_apiKey.contains('BURAYA');

  /// Anahtarı asset dosyasından yükler. Dosya yoksa sessizce geçer.
  static Future<void> loadSecrets() async {
    try {
      final raw = await rootBundle.loadString(_secretsAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (_apiKey.isEmpty) {
        _apiKey = json['FIRESOFT_REDIRECT_API_KEY']?.toString().trim() ?? '';
      }
      final fileBaseUrl = json['FIRESOFT_REDIRECT_BASE_URL']?.toString().trim();
      if (_baseUrl == _defaultBaseUrl &&
          fileBaseUrl != null &&
          fileBaseUrl.isNotEmpty) {
        _baseUrl = fileBaseUrl;
      }
    } catch (_) {
      // Dosya yok veya bozuk: özellik "ayarlanmamış" olarak görünür.
    }
  }

  final Dio _dio;

  Future<DynamicLink> createLink({
    required String target,
    String targetIos = '',
    String targetAndroid = '',
    String title = '',
  }) async {
    final data = await _request(
      'POST',
      '/links',
      body: {
        'target': target,
        if (targetIos.isNotEmpty) 'target_ios': targetIos,
        if (targetAndroid.isNotEmpty) 'target_android': targetAndroid,
        if (title.isNotEmpty) 'title': title,
        'length': 6,
      },
    );
    return DynamicLink.fromJson(data!);
  }

  Future<DynamicLink> getLink(String code) async {
    final data = await _request('GET', '/links/${Uri.encodeComponent(code)}');
    return DynamicLink.fromJson(data!);
  }

  /// Yalnızca verilen alanları günceller (PATCH).
  Future<DynamicLink> updateLink(
    String code, {
    String? target,
    String? targetIos,
    String? targetAndroid,
    String? title,
    bool? active,
  }) async {
    final data = await _request(
      'PATCH',
      '/links/${Uri.encodeComponent(code)}',
      body: {
        if (target != null) 'target': target,
        if (targetIos != null) 'target_ios': targetIos,
        if (targetAndroid != null) 'target_android': targetAndroid,
        if (title != null) 'title': title,
        if (active != null) 'active': active,
      },
    );
    return DynamicLink.fromJson(data!);
  }

  Future<void> deleteLink(String code) async {
    await _request('DELETE', '/links/${Uri.encodeComponent(code)}');
  }

  Future<LinkStats> getStats(String code, {int days = 30}) async {
    final data = await _request(
      'GET',
      '/links/${Uri.encodeComponent(code)}/stats',
      query: {'days': days},
    );
    return LinkStats.fromJson(data!);
  }

  Future<Map<String, dynamic>?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    if (!isConfigured) {
      throw const DynamicLinkException(
        'not_configured',
        'FIRESOFT_REDIRECT_API_KEY is not set.',
      );
    }
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        '$_baseUrl/api/v1$path',
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: {'X-API-Key': _apiKey}),
      );
    } on DioException catch (e) {
      throw DynamicLinkException('network', e.message ?? e.type.name);
    }

    final status = response.statusCode ?? 0;
    if (status == 204) return null;
    final json = response.data;
    if (status >= 400) {
      if (json is Map && json['error'] is Map) {
        final error = json['error'] as Map;
        throw DynamicLinkException(
          error['code']?.toString() ?? 'error',
          error['message']?.toString() ?? 'HTTP $status',
        );
      }
      throw DynamicLinkException('http_$status', 'HTTP $status');
    }
    if (json is Map && json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    throw const DynamicLinkException('invalid_response', 'Unexpected response');
  }
}
