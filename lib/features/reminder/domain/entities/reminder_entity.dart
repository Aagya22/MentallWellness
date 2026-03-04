import 'package:equatable/equatable.dart';

class ReminderEntity extends Equatable {
  final String id;
  final String title;
  /// Canonical format: "HH:mm" (24h). Legacy values may exist.
  final String time;
  final String type; // journal | mood | exercise
  final List<int> daysOfWeek; // 0 (Sun) .. 6 (Sat)
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderEntity({
    required this.id,
    required this.title,
    required this.time,
    required this.type,
    required this.daysOfWeek,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        time,
        type,
        daysOfWeek,
        enabled,
        createdAt,
        updatedAt,
      ];
}
