import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/reminder/data/models/reminder_api_model.dart';
import 'package:mentalwellness/features/reminder/data/models/reminder_notification_api_model.dart';

final reminderRemoteDatasourceProvider = Provider<ReminderRemoteDatasource>((ref) {
  return ReminderRemoteDatasource(apiClient: ref.read(apiClientProvider));
});

class ReminderRemoteDatasource {
  final ApiClient _apiClient;

  ReminderRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ReminderApiModel>> getReminders() async {
    final res = await _apiClient.get(ApiEndpoints.reminders);

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => ReminderApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch reminders');
  }

  Future<ReminderApiModel> createReminder({
    required String title,
    required String time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.reminders,
      data: {
        'title': title.trim(),
        'time': time.trim(),
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (enabled != null) 'enabled': enabled,
      },
    );

    if (res.data['success'] == true) {
      return ReminderApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to create reminder');
  }

  Future<ReminderApiModel> updateReminder({
    required String id,
    String? title,
    String? time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    final res = await _apiClient.put(
      '${ApiEndpoints.reminders}/$id',
      data: {
        if (title != null) 'title': title.trim(),
        if (time != null) 'time': time.trim(),
        if (type != null) 'type': type.trim(),
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (enabled != null) 'enabled': enabled,
      },
    );

    if (res.data['success'] == true) {
      return ReminderApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to update reminder');
  }

  Future<void> deleteReminder({required String id}) async {
    final res = await _apiClient.delete('${ApiEndpoints.reminders}/$id');

    if (res.data['success'] == true) {
      return;
    }

    throw Exception(res.data['message'] ?? 'Failed to delete reminder');
  }

  Future<ReminderApiModel> toggleReminder({required String id}) async {
    final res = await _apiClient.patch('${ApiEndpoints.reminders}/$id/toggle');

    if (res.data['success'] == true) {
      return ReminderApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to toggle reminder');
  }

  Future<List<ReminderNotificationApiModel>> getNotificationHistory({int limit = 20}) async {
    final res = await _apiClient.get(
      ApiEndpoints.reminderNotifications,
      queryParameters: {
        'limit': limit,
      },
    );

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => ReminderNotificationApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch notification history');
  }

  Future<ReminderNotificationApiModel> markNotificationRead({required String id}) async {
    final res = await _apiClient.patch('${ApiEndpoints.reminderNotifications}/$id/read');

    if (res.data['success'] == true) {
      return ReminderNotificationApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to mark notification read');
  }

  Future<int> markAllNotificationsRead() async {
    final res = await _apiClient.patch('${ApiEndpoints.reminderNotifications}/read-all');

    if (res.data['success'] == true) {
      final data = res.data['data'] as Map<String, dynamic>?;
      final updated = data?['updatedCount'];
      return int.tryParse(updated?.toString() ?? '') ?? 0;
    }

    throw Exception(res.data['message'] ?? 'Failed to mark all notifications read');
  }

  Future<int> clearNotificationHistory() async {
    final res = await _apiClient.delete(ApiEndpoints.reminderNotifications);

    if (res.data['success'] == true) {
      final data = res.data['data'] as Map<String, dynamic>?;
      final deleted = data?['deletedCount'];
      return int.tryParse(deleted?.toString() ?? '') ?? 0;
    }

    throw Exception(res.data['message'] ?? 'Failed to clear notification history');
  }

  Future<List<ReminderNotificationApiModel>> checkDueReminders({int windowMinutes = 2}) async {
    final res = await _apiClient.get(
      ApiEndpoints.dueReminders,
      queryParameters: {
        'windowMinutes': windowMinutes,
      },
    );

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => ReminderNotificationApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to check due reminders');
  }
}
