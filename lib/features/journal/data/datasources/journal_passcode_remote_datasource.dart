import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';

final journalPasscodeRemoteDatasourceProvider =
    Provider<JournalPasscodeRemoteDatasource>((ref) {
      return JournalPasscodeRemoteDatasource(
        apiClient: ref.read(apiClientProvider),
      );
    });

class JournalUnlockResponse {
  final String token;
  final int expiresInSeconds;

  const JournalUnlockResponse({
    required this.token,
    required this.expiresInSeconds,
  });

  factory JournalUnlockResponse.fromJson(Map<String, dynamic> json) {
    return JournalUnlockResponse(
      token: (json['token'] ?? '') as String,
      expiresInSeconds: (json['expiresInSeconds'] ?? 0) as int,
    );
  }
}

class JournalPasscodeRemoteDatasource {
  final ApiClient _apiClient;

  JournalPasscodeRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<bool> getStatus() async {
    final res = await _apiClient.get(ApiEndpoints.journalPasscode);

    if (res.data['success'] == true) {
      final data = (res.data['data'] as Map<String, dynamic>?) ?? const {};
      return (data['enabled'] == true);
    }

    throw Exception(
      res.data['message'] ?? 'Failed to fetch journal passcode status',
    );
  }

  Future<bool> setPasscode({
    required String passcode,
    required String password,
  }) async {
    final res = await _apiClient.put(
      ApiEndpoints.journalPasscode,
      data: {'passcode': passcode, 'password': password},
    );

    if (res.data['success'] == true) {
      final data = (res.data['data'] as Map<String, dynamic>?) ?? const {};
      return (data['enabled'] == true);
    }

    throw Exception(res.data['message'] ?? 'Failed to set journal passcode');
  }

  Future<bool> clearPasscode({required String password}) async {
    final res = await _apiClient.delete(
      ApiEndpoints.journalPasscode,
      data: {'password': password},
    );

    if (res.data['success'] == true) {
      final data = (res.data['data'] as Map<String, dynamic>?) ?? const {};
      return (data['enabled'] == true);
    }

    throw Exception(res.data['message'] ?? 'Failed to clear journal passcode');
  }

  Future<JournalUnlockResponse> verifyPasscode({
    required String passcode,
  }) async {
    final res = await _apiClient.post(
      ApiEndpoints.journalPasscodeVerify,
      data: {'passcode': passcode},
    );

    if (res.data['success'] == true) {
      final data = (res.data['data'] as Map<String, dynamic>?) ?? const {};
      return JournalUnlockResponse.fromJson(data);
    }

    throw Exception(res.data['message'] ?? 'Failed to verify journal passcode');
  }
}
