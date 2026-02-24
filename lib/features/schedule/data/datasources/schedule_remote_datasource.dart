import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/schedule/data/models/schedule_api_model.dart';

final scheduleRemoteDatasourceProvider = Provider<ScheduleRemoteDatasource>((ref) {
  return ScheduleRemoteDatasource(apiClient: ref.read(apiClientProvider));
});

class ScheduleRemoteDatasource {
  final ApiClient _apiClient;

  ScheduleRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ScheduleApiModel>> getSchedules({
    String? q,
    String? from,
    String? to,
  }) async {
    final res = await _apiClient.get(
      ApiEndpoints.schedules,
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (from != null && from.trim().isNotEmpty) 'from': from.trim(),
        if (to != null && to.trim().isNotEmpty) 'to': to.trim(),
      },
    );

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => ScheduleApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch schedules');
  }

  Future<ScheduleApiModel> createSchedule({
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.schedules,
      data: {
        'title': title.trim(),
        'date': date.trim(),
        'time': time.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
      },
    );

    if (res.data['success'] == true) {
      return ScheduleApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to create schedule');
  }

  Future<ScheduleApiModel> updateSchedule({
    required String id,
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) async {
    final res = await _apiClient.put(
      '${ApiEndpoints.schedules}/$id',
      data: {
        'title': title.trim(),
        'date': date.trim(),
        'time': time.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
      },
    );

    if (res.data['success'] == true) {
      return ScheduleApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to update schedule');
  }

  Future<void> deleteSchedule({
    required String id,
  }) async {
    final res = await _apiClient.delete('${ApiEndpoints.schedules}/$id');

    if (res.data['success'] == true) {
      return;
    }

    throw Exception(res.data['message'] ?? 'Failed to delete schedule');
  }
}
