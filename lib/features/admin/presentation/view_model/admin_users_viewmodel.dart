import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/admin/data/models/admin_user_model.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_users_state.dart';

final adminUsersViewModelProvider =
    NotifierProvider<AdminUsersViewModel, AdminUsersState>(
      AdminUsersViewModel.new,
    );

class AdminUsersViewModel extends Notifier<AdminUsersState> {
  late final ApiClient _apiClient;

  @override
  AdminUsersState build() {
    _apiClient = ref.read(apiClientProvider);
    return const AdminUsersState();
  }

  Future<void> fetchUsers({int? page, int? limit, String? search}) async {
    final nextPage = page ?? state.page;
    final nextLimit = limit ?? state.limit;
    final nextSearch = search ?? state.search;

    state = state.copyWith(
      status: AdminUsersStatus.loading,
      page: nextPage,
      limit: nextLimit,
      search: nextSearch,
      errorMessage: null,
    );

    try {
      final res = await _apiClient.get(
        ApiEndpoints.adminUsers,
        queryParameters: {
          'page': nextPage,
          'limit': nextLimit,
          if (nextSearch.trim().isNotEmpty) 'search': nextSearch.trim(),
        },
      );

      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception((data['message'] ?? 'Failed to load users').toString());
      }

      final rawUsers = (data['data'] as List<dynamic>? ?? const []);
      final users = rawUsers
          .whereType<Map<String, dynamic>>()
          .map(AdminUserModel.fromJson)
          .toList(growable: false);

      final pagination = (data['pagination'] as Map<String, dynamic>?);
      final total = (pagination?['total'] is int)
          ? pagination!['total'] as int
          : users.length;
      final totalPages = (pagination?['totalPages'] is int)
          ? pagination!['totalPages'] as int
          : (total == 0 ? 0 : ((total + nextLimit - 1) ~/ nextLimit));

      state = state.copyWith(
        status: AdminUsersStatus.loaded,
        users: users,
        total: total,
        totalPages: totalPages,
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> deleteUser(String userId) async {
    if (userId.isEmpty) return false;

    state = state.copyWith(
      status: AdminUsersStatus.deleting,
      errorMessage: null,
    );
    try {
      final res = await _apiClient.delete('${ApiEndpoints.adminUsers}/$userId');
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to delete user').toString(),
        );
      }

      // Refresh current page.
      await fetchUsers(
        page: state.page,
        limit: state.limit,
        search: state.search,
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AdminUsersStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
