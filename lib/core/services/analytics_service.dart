import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver? _observer;

  FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(analytics: _analytics);
    return _observer!;
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('Analytics User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('Analytics User Property set: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user property: $e');
      }
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('Analytics Event: $name ${parameters != null ? "with params: $parameters" : ""}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging event: $e');
      }
    }
  }

  Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    if (kDebugMode) {
      print('Screen View: $screenName');
    }
  }

  Future<void> logNFCRead({
    required String nfcType,
    int? dataSize,
  }) async {
    await logEvent(
      name: 'nfc_read',
      parameters: {
        'nfc_type': nfcType,
        if (dataSize != null) 'data_size': dataSize,
      },
    );
  }

  Future<void> logNFCWrite({
    required String nfcType,
    required String writeType,
    int? dataSize,
  }) async {
    await logEvent(
      name: 'nfc_write',
      parameters: {
        'nfc_type': nfcType,
        'write_type': writeType,
        if (dataSize != null) 'data_size': dataSize,
      },
    );
  }

  Future<void> logNFCError({
    required String errorType,
    String? errorMessage,
  }) async {
    await logEvent(
      name: 'nfc_error',
      parameters: {
        'error_type': errorType,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  Future<void> logPurchase({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await _analytics.logPurchase(
      value: price,
      currency: currency,
      parameters: {
        'product_id': productId,
      },
    );
  }

  Future<void> logAdClick({
    required String adType,
    String? adPlacement,
  }) async {
    await logEvent(
      name: 'ad_click',
      parameters: {
        'ad_type': adType,
        if (adPlacement != null) 'ad_placement': adPlacement,
      },
    );
  }

  Future<void> logAdImpression({
    required String adType,
    String? adPlacement,
  }) async {
    await logEvent(
      name: 'ad_impression',
      parameters: {
        'ad_type': adType,
        if (adPlacement != null) 'ad_placement': adPlacement,
      },
    );
  }

  Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method??'',
    );
  }

  Future<void> logSearch({
    required String searchTerm,
  }) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  Future<void> logLanguageChange({
    required String language,
  }) async {
    await logEvent(
      name: 'language_change',
      parameters: {
        'language': language,
      },
    );
  }

  Future<void> logThemeChange({
    required String theme,
  }) async {
    await logEvent(
      name: 'theme_change',
      parameters: {
        'theme': theme,
      },
    );
  }

  Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object>? additionalParams,
  }) async {
    await logEvent(
      name: 'feature_usage',
      parameters: {
        'feature_name': featureName,
        ...?additionalParams,
      },
    );
  }

  Future<void> logButtonClick({
    required String buttonName,
    String? screenName,
  }) async {
    await logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  Future<void> logWifiConnection({
    required String ssid,
    required bool success,
  }) async {
    await logEvent(
      name: 'wifi_connection',
      parameters: {
        'ssid': ssid,
        'success': success,
      },
    );
  }

  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }

  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
  }

  Future<void> logTutorialComplete() async {
    await _analytics.logTutorialComplete();
  }

  Future<void> logLogin({
    required String method,
  }) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({
    required String method,
  }) async {
    await _analytics.logSignUp(signUpMethod: method);
  }
}
