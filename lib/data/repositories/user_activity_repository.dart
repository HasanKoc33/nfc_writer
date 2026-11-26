import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_messaging_service.dart';

class UserActivityRepository {
  static final UserActivityRepository _instance =
      UserActivityRepository._internal();
  factory UserActivityRepository() => _instance;
  UserActivityRepository._internal();

  static const String _userIdKey = 'user_id';

  Future<void> registerUserActivity() async {
    try {
      final fcmToken = FirebaseMessagingService().fcmToken;
      final userId = await _getUserId();
      final lastAppOpen = await FirebaseMessagingService().getLastAppOpenTime();

      if (fcmToken != null && userId != null) {
        final data = {
          'user_id': userId,
          'fcm_token': fcmToken,
          'last_app_open': lastAppOpen?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'platform': defaultTargetPlatform.toString(),
        };

        if (kDebugMode) {
          print('User activity data prepared: $data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering user activity: $e');
      }
    }
  }

  Future<void> updateUserActivity() async {
    try {
      await FirebaseMessagingService().updateLastAppOpenTime();
      await registerUserActivity();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user activity: $e');
      }
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  Future<void> sendInactiveUserNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    if (kDebugMode) {
      print('Notification would be sent to: $fcmToken');
      print('Title: $title');
      print('Body: $body');
    }
  }
}
