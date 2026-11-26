import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  void _logScreenView() {
    final screenName = T.toString().replaceAll('State', '').replaceAll('_', '');
    _analytics.logScreenView(
      screenName: screenName,
      screenClass: T.toString(),
    );
  }

  void logButtonClick(String buttonName) {
    final screenName = T.toString().replaceAll('State', '').replaceAll('_', '');
    _analytics.logButtonClick(
      buttonName: buttonName,
      screenName: screenName,
    );
  }

  void logFeatureUsage(String featureName, {Map<String, Object>? params}) {
    _analytics.logFeatureUsage(
      featureName: featureName,
      additionalParams: params,
    );
  }

  void logError(String errorType, String errorMessage, {String? stackTrace}) {
    _analytics.logError(
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
    );
  }
}
