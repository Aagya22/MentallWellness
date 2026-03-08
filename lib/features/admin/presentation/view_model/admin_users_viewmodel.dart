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

  Future<void> fetchUsers({
    int? page,
    int? limit,
    String? search,
    bool append = false,
  }) async {
    final nextPage = page ?? state.page;
    final nextLimit = limit ?? state.limit;
    final nextSearch = search ?? state.search;

    if (append) {
      if (state.isLoadingMore) return;

      final endReached = state.totalPages > 0 && nextPage > state.totalPages;
      if (endReached) return;

      state = state.copyWith(
        page: nextPage,
        limit: nextLimit,
        search: nextSearch,
        isLoadingMore: true,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(
        status: AdminUsersStatus.loading,
        page: nextPage,
        limit: nextLimit,
        search: nextSearch,
        isLoadingMore: false,
        errorMessage: null,
      );
    }

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

      final pagination = data['pagination'] as Map<String, dynamic>?;
      final total = (pagination?['total'] is int)
          ? pagination!['total'] as int
          : users.length;
      final totalPages = (pagination?['totalPages'] is int)
          ? pagination!['totalPages'] as int
          : (total == 0 ? 0 : ((total + nextLimit - 1) ~/ nextLimit));

      if (append) {
        final merged = <AdminUserModel>[...state.users];
        final seenIds = merged.map((e) => e.id).toSet();

        for (final user in users) {
          if (seenIds.add(user.id)) {
            merged.add(user);
          }
        }

        state = state.copyWith(
          status: AdminUsersStatus.loaded,
          users: merged,
          page: nextPage,
          limit: nextLimit,
          search: nextSearch,
          total: total,
          totalPages: totalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AdminUsersStatus.loaded,
          users: users,
          page: nextPage,
          limit: nextLimit,
          search: nextSearch,
          total: total,
          totalPages: totalPages,
          isLoadingMore: false,
          errorMessage: null,
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');

      final hasExistingList = state.users.isNotEmpty;
      state = state.copyWith(
        status: hasExistingList
            ? AdminUsersStatus.loaded
            : AdminUsersStatus.error,
        errorMessage: message,
        isLoadingMore: false,
      );
    } catch (e) {
      final hasExistingList = state.users.isNotEmpty;
      state = state.copyWith(
        status: hasExistingList
            ? AdminUsersStatus.loaded
            : AdminUsersStatus.error,
        errorMessage: e.toString(),
        isLoadingMore: false,
      );
    }
  }

  Future<void> loadMoreUsers() async {
    if (state.status == AdminUsersStatus.loading || state.isLoadingMore) return;
    if (state.totalPages > 0 && state.page >= state.totalPages) return;

    await fetchUsers(
      page: state.page + 1,
      limit: state.limit,
      search: state.search,
      append: true,
    );
  }

  Future<void> refreshLoadedPages({
    int? loadedPages,
    int? limit,
    String? search,
  }) async {
    final pagesToLoad = (loadedPages ?? state.page).clamp(1, 999999);
    final nextLimit = limit ?? state.limit;
    final nextSearch = search ?? state.search;

    await fetchUsers(page: 1, limit: nextLimit, search: nextSearch);

    for (var page = 2; page <= pagesToLoad; page++) {
      await fetchUsers(
        page: page,
        limit: nextLimit,
        search: nextSearch,
        append: true,
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
