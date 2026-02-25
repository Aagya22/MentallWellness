import 'package:equatable/equatable.dart';

class ReminderNotificationEntity extends Equatable {
  final String id;
  final String reminderId;
  final String title;
  final String type; // journal | mood | exercise
  final DateTime scheduledFor;
  final DateTime deliveredAt;
  final DateTime? readAt;

  const ReminderNotificationEntity({
    required this.id,
    required this.reminderId,
    required this.title,
    required this.type,
    required this.scheduledFor,
    required this.deliveredAt,
    required this.readAt,
  });

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, reminderId, title, type, scheduledFor, deliveredAt, readAt];
}
