import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/services/notifications/local_notification_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
