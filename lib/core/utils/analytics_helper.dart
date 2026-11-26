import '../services/analytics_service.dart';

class AnalyticsHelper {
  static final AnalyticsService _analytics = AnalyticsService();

  static Future<void> trackNFCRead({
    required String nfcType,
    int? dataSize,
  }) async {
    await _analytics.logNFCRead(
      nfcType: nfcType,
      dataSize: dataSize,
    );
  }

  static Future<void> trackNFCWrite({
    required String nfcType,
    required String writeType,
    int? dataSize,
  }) async {
    await _analytics.logNFCWrite(
      nfcType: nfcType,
      writeType: writeType,
      dataSize: dataSize,
    );
  }

  static Future<void> trackNFCError({
    required String errorType,
    String? errorMessage,
  }) async {
    await _analytics.logNFCError(
      errorType: errorType,
      errorMessage: errorMessage,
    );
  }

  static Future<void> trackPurchase({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await _analytics.logPurchase(
      productId: productId,
      price: price,
      currency: currency,
    );
  }

  static Future<void> trackAdClick({
    required String adType,
    String? adPlacement,
  }) async {
    await _analytics.logAdClick(
      adType: adType,
      adPlacement: adPlacement,
    );
  }

  static Future<void> trackAdImpression({
    required String adType,
    String? adPlacement,
  }) async {
    await _analytics.logAdImpression(
      adType: adType,
      adPlacement: adPlacement,
    );
  }

  static Future<void> trackLanguageChange(String language) async {
    await _analytics.logLanguageChange(language: language);
  }

  static Future<void> trackThemeChange(String theme) async {
    await _analytics.logThemeChange(theme: theme);
  }

  static Future<void> trackWifiConnection({
    required String ssid,
    required bool success,
  }) async {
    await _analytics.logWifiConnection(
      ssid: ssid,
      success: success,
    );
  }

  static Future<void> trackShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }

  static Future<void> trackSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  static Future<void> trackCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }

  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(userId);
  }

  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }
}
