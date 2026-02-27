import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/admin/data/models/admin_user_model.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_user_crud_state.dart';

final adminUserCrudViewModelProvider =
    NotifierProvider<AdminUserCrudViewModel, AdminUserCrudState>(
      AdminUserCrudViewModel.new,
    );

class AdminUserCrudViewModel extends Notifier<AdminUserCrudState> {
  late final ApiClient _apiClient;

  @override
  AdminUserCrudState build() {
    _apiClient = ref.read(apiClientProvider);
    return const AdminUserCrudState();
  }

  Future<AdminUserModel?> fetchUserById(String userId) async {
    if (userId.isEmpty) return null;
    state = state.copyWith(status: AdminUserCrudStatus.loading, message: null);
    try {
      final res = await _apiClient.get('${ApiEndpoints.adminUsers}/$userId');
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception((data['message'] ?? 'Failed to load user').toString());
      }
      final raw = (data['data'] as Map<String, dynamic>);
      final user = AdminUserModel.fromJson(raw);
      state = state.copyWith(status: AdminUserCrudStatus.success, user: user);
      return user;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      state = state.copyWith(
        status: AdminUserCrudStatus.error,
        message: message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        status: AdminUserCrudStatus.error,
        message: e.toString(),
      );
      return null;
    }
  }

  Future<bool> createUser({
    required String fullName,
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    File? image,
  }) async {
    state = state.copyWith(status: AdminUserCrudStatus.loading, message: null);
    try {
      final formData = FormData.fromMap({
        'fullName': fullName,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
      });

      if (image != null) {
        final fileName = image.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(image.path, filename: fileName),
          ),
        );
      }

      final res = await _apiClient.post(
        ApiEndpoints.adminUsers,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to create user').toString(),
        );
      }

      final raw = data['data'];
      final created = raw is Map<String, dynamic>
          ? AdminUserModel.fromJson(raw)
          : null;
      state = state.copyWith(
        status: AdminUserCrudStatus.success,
        user: created,
        message: 'User created',
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      state = state.copyWith(
        status: AdminUserCrudStatus.error,
        message: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AdminUserCrudStatus.error,
        message: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String fullName,
    required String email,
    required String username,
    required String phoneNumber,
    File? image,
  }) async {
    if (userId.isEmpty) return false;

    state = state.copyWith(status: AdminUserCrudStatus.loading, message: null);
    try {
      final formData = FormData.fromMap({
        'fullName': fullName,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
      });

      if (image != null) {
        final fileName = image.path.split('/').last;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(image.path, filename: fileName),
          ),
        );
      }

      final res = await _apiClient.put(
        '${ApiEndpoints.adminUsers}/$userId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to update user').toString(),
        );
      }

      final raw = data['data'];
      final updated = raw is Map<String, dynamic>
          ? AdminUserModel.fromJson(raw)
          : null;
      state = state.copyWith(
        status: AdminUserCrudStatus.success,
        user: updated,
        message: 'User updated',
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      state = state.copyWith(
        status: AdminUserCrudStatus.error,
        message: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AdminUserCrudStatus.error,
        message: e.toString(),
      );
      return false;
    }
  }
}
