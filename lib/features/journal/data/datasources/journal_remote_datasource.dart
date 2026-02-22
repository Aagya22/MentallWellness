import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/journal/data/models/journal_api_model.dart';

final journalRemoteDatasourceProvider = Provider<JournalRemoteDatasource>((ref) {
  return JournalRemoteDatasource(apiClient: ref.read(apiClientProvider));
});

class JournalRemoteDatasource {
  final ApiClient _apiClient;

  JournalRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<JournalApiModel>> getJournals({String? q}) async {
    final res = await _apiClient.get(
      ApiEndpoints.journals,
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );

    if (res.data['success'] == true) {
      final list = (res.data['data'] as List).cast<dynamic>();
      return list
          .map((e) => JournalApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.data['message'] ?? 'Failed to fetch journals');
  }

  Future<JournalApiModel> createJournal({
    required String title,
    required String content,
    DateTime? date,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.journals,
      data: {
        'title': title,
        'content': content,
        if (date != null) 'date': date.toIso8601String(),
      },
    );

    if (res.data['success'] == true) {
      return JournalApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to create journal');
  }

  Future<JournalApiModel> updateJournal({
    required String id,
    String? title,
    String? content,
    DateTime? date,
  }) async {
    final res = await _apiClient.put(
      '${ApiEndpoints.journals}/$id',
      data: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (date != null) 'date': date.toIso8601String(),
      },
    );

    if (res.data['success'] == true) {
      return JournalApiModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }

    throw Exception(res.data['message'] ?? 'Failed to update journal');
  }

  Future<void> deleteJournal({required String id}) async {
    final res = await _apiClient.delete('${ApiEndpoints.journals}/$id');

    if (res.data['success'] == true) {
      return;
    }

    throw Exception(res.data['message'] ?? 'Failed to delete journal');
  }
}
