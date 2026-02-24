import 'package:equatable/equatable.dart';

class GuidedHistorySessionEntity extends Equatable {
  final String id;
  final String title;
  final String? category;
  final int duration;
  final int? durationSeconds;
  final DateTime date;

  const GuidedHistorySessionEntity({
    required this.id,
    required this.title,
    this.category,
    required this.duration,
    this.durationSeconds,
    required this.date,
  });

  @override
  List<Object?> get props => [id, title, category, duration, durationSeconds, date];
}

class GuidedHistoryDayEntity extends Equatable {
  final String date; // YYYY-MM-DD
  final int totalMinutes;
  final List<GuidedHistorySessionEntity> sessions;

  const GuidedHistoryDayEntity({
    required this.date,
    required this.totalMinutes,
    required this.sessions,
  });

  @override
  List<Object?> get props => [date, totalMinutes, sessions];
}
