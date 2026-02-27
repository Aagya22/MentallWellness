import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/admin/data/models/admin_user_model.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_dashboard_state.dart';

final adminDashboardViewModelProvider =
    NotifierProvider<AdminDashboardViewModel, AdminDashboardState>(
      AdminDashboardViewModel.new,
    );

class AdminDashboardViewModel extends Notifier<AdminDashboardState> {
  late final ApiClient _apiClient;

  @override
  AdminDashboardState build() {
    _apiClient = ref.read(apiClientProvider);
    return const AdminDashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(
      status: AdminDashboardStatus.loading,
      errorMessage: null,
    );
    try {
      // Fetch enough users to compute stats (mirrors web dashboard behavior).
      final res = await _apiClient.get(
        ApiEndpoints.adminUsers,
        queryParameters: const {'page': 1, 'limit': 1000},
      );

      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to load dashboard').toString(),
        );
      }

      final rawUsers = (data['data'] as List<dynamic>? ?? const []);
      final users = rawUsers
          .whereType<Map<String, dynamic>>()
          .map(AdminUserModel.fromJson)
          .toList(growable: false);

      final totalUsers = users.length;
      final totalAdmins = users.where((u) => u.role == 'admin').length;
      final regularUsers = totalUsers - totalAdmins;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentUsers30Days = users
          .where(
            (u) => u.createdAt != null && u.createdAt!.isAfter(thirtyDaysAgo),
          )
          .length;

      final recentUsers = [...users]
        ..sort((a, b) {
          final aa = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bb.compareTo(aa);
        });

      state = state.copyWith(
        status: AdminDashboardStatus.loaded,
        totalUsers: totalUsers,
        totalAdmins: totalAdmins,
        regularUsers: regularUsers,
        recentUsers30Days: recentUsers30Days,
        recentUsers: recentUsers.take(5).toList(growable: false),
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? e.message)
          : (e.message ?? 'Network error');
      state = state.copyWith(
        status: AdminDashboardStatus.error,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AdminDashboardStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
