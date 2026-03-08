import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/api/api_client.dart';
import 'package:mentalwellness/core/api/api_endpoints.dart';
import 'package:mentalwellness/features/admin/data/models/admin_notification_model.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_notifications_state.dart';

final adminNotificationsViewModelProvider =
    NotifierProvider<AdminNotificationsViewModel, AdminNotificationsState>(
      AdminNotificationsViewModel.new,
    );

class AdminNotificationsViewModel extends Notifier<AdminNotificationsState> {
  late final ApiClient _apiClient;

  @override
  AdminNotificationsState build() {
    _apiClient = ref.read(apiClientProvider);
    return const AdminNotificationsState();
  }

  Future<void> fetchNotifications({int limit = 50}) async {
    state = state.copyWith(
      status: AdminNotificationsStatus.loading,
      errorMessage: null,
    );

    try {
      final res = await _apiClient.get(
        ApiEndpoints.adminNotifications,
        queryParameters: {'limit': limit},
      );

      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to load notifications').toString(),
        );
      }

      final payload = data['data'] as Map<String, dynamic>? ?? const {};
      final rawNotifications =
          payload['notifications'] as List<dynamic>? ?? const [];

      final notifications = rawNotifications
          .whereType<Map<String, dynamic>>()
          .map(AdminNotificationModel.fromJson)
          .toList(growable: false);

      final unreadCount = payload['unreadCount'] is int
          ? payload['unreadCount'] as int
          : notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
        errorMessage: null,
      );
    } on DioException catch (e) {
      final hasExisting = state.notifications.isNotEmpty;
      state = state.copyWith(
        status: hasExisting
            ? AdminNotificationsStatus.loaded
            : AdminNotificationsStatus.error,
        errorMessage: _extractErrorMessage(e),
      );
    } catch (e) {
      final hasExisting = state.notifications.isNotEmpty;
      state = state.copyWith(
        status: hasExisting
            ? AdminNotificationsStatus.loaded
            : AdminNotificationsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markRead({required String id}) async {
    if (id.isEmpty) return;

    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index == -1 || state.notifications[index].isRead) return;

    final optimistic = [...state.notifications];
    optimistic[index] = optimistic[index].copyWith(readAt: DateTime.now());

    state = state.copyWith(
      notifications: optimistic,
      unreadCount: math.max(0, state.unreadCount - 1),
      status: AdminNotificationsStatus.loaded,
      errorMessage: null,
    );

    try {
      final res = await _apiClient.patch(
        ApiEndpoints.adminNotificationMarkRead(id),
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to mark notification as read').toString(),
        );
      }

      final updatedRaw = data['data'];
      if (updatedRaw is Map<String, dynamic>) {
        final updated = AdminNotificationModel.fromJson(updatedRaw);
        final nextList = [...state.notifications];
        final nextIndex = nextList.indexWhere((n) => n.id == updated.id);
        if (nextIndex != -1) {
          nextList[nextIndex] = updated;
          state = state.copyWith(
            notifications: nextList,
            unreadCount: nextList.where((n) => !n.isRead).length,
            status: AdminNotificationsStatus.loaded,
            errorMessage: null,
          );
        }
      }
    } on DioException catch (e) {
      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        errorMessage: _extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> markAllRead() async {
    state = state.copyWith(
      status: AdminNotificationsStatus.saving,
      errorMessage: null,
    );

    try {
      final res = await _apiClient.patch(
        ApiEndpoints.adminNotificationsReadAll,
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to mark all as read').toString(),
        );
      }

      await fetchNotifications(limit: _effectiveLimit());
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> clearAll() async {
    state = state.copyWith(
      status: AdminNotificationsStatus.saving,
      errorMessage: null,
    );

    try {
      final res = await _apiClient.delete(ApiEndpoints.adminNotifications);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(
          (data['message'] ?? 'Failed to clear notifications').toString(),
        );
      }

      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        notifications: const [],
        unreadCount: 0,
        errorMessage: null,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AdminNotificationsStatus.loaded,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  int _effectiveLimit() {
    return state.notifications.length > 50 ? state.notifications.length : 50;
  }

  String _extractErrorMessage(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    }
    return e.message ?? 'Network error';
  }
}
