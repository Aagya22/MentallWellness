import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';

enum ReminderNotificationsStatus { initial, loading, loaded, saving, error }

class ReminderNotificationsState extends Equatable {
  final ReminderNotificationsStatus status;
  final List<ReminderNotificationEntity> notifications;
  final String? errorMessage;

  const ReminderNotificationsState({
    this.status = ReminderNotificationsStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  ReminderNotificationsState copyWith({
    ReminderNotificationsStatus? status,
    List<ReminderNotificationEntity>? notifications,
    String? errorMessage,
  }) {
    return ReminderNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}
