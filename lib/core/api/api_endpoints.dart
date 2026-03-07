import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const bool isPhysicalDevice = true;
  static const String _ipAddress = '192.168.1.9';
  static const int _port = 5050;

  static String get baseUrl {
    if (kIsWeb) return 'http://$_ipAddress:$_port/';
    if (isPhysicalDevice) return 'http://$_ipAddress:$_port/';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port/';
    if (Platform.isIOS) return 'http://localhost:$_port/';
    return 'http://localhost:$_port/';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String user = '/api/auth';
  static const String userLogin = '/api/auth/login';
  static const String userRegister = '/api/auth/register';
  static const String userUpdateProfile = '/api/auth/update-profile';
  static const String userWhoAmI = '/api/auth/whoami';
  static const String changePassword = '/api/auth/change-password';

  // Journal passcode
  static const String journalPasscode = '/api/auth/journal-passcode';
  static const String journalPasscodeVerify =
      '/api/auth/journal-passcode/verify';

  // Admin
  static const String adminUsers = '/api/admin/users';
  static const String adminNotifications = '/api/admin/notifications';
  static const String adminNotificationsReadAll =
      '/api/admin/notifications/read-all';

  static String adminNotificationMarkRead(String id) =>
      '/api/admin/notifications/$id/read';

  // Journals
  static const String journals = '/api/journals';

  // Moods
  static const String moods = '/api/moods';
  static const String moodsOverview = '/api/moods/overview';
  static const String moodsAnalytics = '/api/moods/analytics';
  static const String moodsByDate = '/api/moods/by-date';
  static const String moodsRange = '/api/moods/range';

  // Exercises
  static const String exercises = '/api/exercises';
  static const String guidedExercisesComplete =
      '/api/exercises/guided/complete';
  static const String guidedExercisesHistory = '/api/exercises/guided/history';
  static const String exercisesHistory = '/api/exercises/history';

  // Schedules (Calendar)
  static const String schedules = '/api/schedules';

  // Reminders
  static const String reminders = '/api/reminders';
  static const String reminderNotifications = '/api/reminders/notifications';
  static const String dueReminders = '/api/reminders/due';

  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$base$path';
  }
}
