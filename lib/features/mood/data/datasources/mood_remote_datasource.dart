import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/mood/data/models/mood_api_model.dart';
import 'package:mentalwellness/features/mood/data/models/mood_overview_api_model.dart';
import 'package:mentalwellness/features/mood/data/models/mood_range_api_model.dart';

final moodRemoteDatasourceProvider = Provider<MoodRemoteDatasource>((ref) {
  return MoodRemoteDatasource(apiClient: ref.read(apiClientProvider));
});

class MoodRemoteDatasource {
  final ApiClient _apiClient;

  MoodRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<MoodOverviewApiModel> getOverview() async {
    final res = await _apiClient.get(ApiEndpoints.moodsOverview);
    if (res.data['success'] == true) {
      return MoodOverviewApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    throw Exception(res.data['message'] ?? 'Failed to fetch mood overview');
  }

  Future<List<MoodApiModel>> getMoods() async {
    final res = await _apiClient.get(ApiEndpoints.moods);
    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => MoodApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res.data['message'] ?? 'Failed to fetch moods');
  }

  Future<MoodApiModel> createMood({
    required int mood,
    String? moodType,
    String? note,
    DateTime? date,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.moods,
      data: {
        'mood': mood,
        if (moodType != null && moodType.trim().isNotEmpty) 'moodType': moodType.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (date != null) 'date': date.toIso8601String(),
      },
    );

    if (res.data['success'] == true) {
      return MoodApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to save mood');
  }

  Future<List<MoodRangeApiModel>> getMoodsInRange({
    required String from,
    required String to,
  }) async {
    final res = await _apiClient.get(
      ApiEndpoints.moodsRange,
      queryParameters: {'from': from, 'to': to},
    );

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => MoodRangeApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch moods');
  }
}
