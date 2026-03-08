import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/admin/data/models/admin_notification_model.dart';

enum AdminNotificationsStatus { initial, loading, loaded, saving, error }

class AdminNotificationsState extends Equatable {
  final AdminNotificationsStatus status;
  final List<AdminNotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const AdminNotificationsState({
    this.status = AdminNotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  AdminNotificationsState copyWith({
    AdminNotificationsStatus? status,
    List<AdminNotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return AdminNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, unreadCount, errorMessage];
}
