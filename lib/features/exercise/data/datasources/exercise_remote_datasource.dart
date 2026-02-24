import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/exercise/data/models/exercise_api_model.dart';
import 'package:mentalwellness/features/exercise/data/models/guided_history_api_model.dart';

final exerciseRemoteDatasourceProvider = Provider<ExerciseRemoteDatasource>((ref) {
  return ExerciseRemoteDatasource(apiClient: ref.read(apiClientProvider));
});

class ExerciseRemoteDatasource {
  final ApiClient _apiClient;

  ExerciseRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ExerciseApiModel>> getExercises() async {
    final res = await _apiClient.get(ApiEndpoints.exercises);

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => ExerciseApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch exercises');
  }

  Future<ExerciseApiModel> createExercise({
    required String type,
    required int duration,
    DateTime? date,
    String? notes,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.exercises,
      data: {
        'type': type.trim(),
        'duration': duration,
        if (date != null) 'date': date.toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    if (res.data['success'] == true) {
      return ExerciseApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to create exercise');
  }

  Future<ExerciseApiModel> completeGuidedExercise({
    required String title,
    required String category,
    required int plannedDurationSeconds,
    required int elapsedSeconds,
    DateTime? completedAt,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.guidedExercisesComplete,
      data: {
        'title': title.trim(),
        'category': category.trim(),
        'plannedDurationSeconds': plannedDurationSeconds,
        'elapsedSeconds': elapsedSeconds,
        if (completedAt != null) 'completedAt': completedAt.toIso8601String(),
      },
    );

    if (res.data['success'] == true) {
      return ExerciseApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to save guided session');
  }

  Future<List<GuidedHistoryDayApiModel>> getGuidedHistory({
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _apiClient.get(
      ApiEndpoints.guidedExercisesHistory,
      queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => GuidedHistoryDayApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch guided history');
  }
}
