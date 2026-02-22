import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';

class MoodAverageEntity extends Equatable {
  final double score;
  final String label;

  const MoodAverageEntity({required this.score, required this.label});

  @override
  List<Object?> get props => [score, label];
}

class MoodMostFrequentEntity extends Equatable {
  final String key;
  final int count;

  const MoodMostFrequentEntity({required this.key, required this.count});

  @override
  List<Object?> get props => [key, count];
}

class MoodOverviewDayEntity extends Equatable {
  final DateTime date;
  final MoodEntity? entry;

  const MoodOverviewDayEntity({required this.date, required this.entry});

  @override
  List<Object?> get props => [date, entry];
}

class MoodOverviewEntity extends Equatable {
  final DateTime weekStart;
  final List<MoodOverviewDayEntity> days;
  final MoodAverageEntity? avgThisWeek;
  final int streak;
  final MoodMostFrequentEntity? mostFrequent;

  const MoodOverviewEntity({
    required this.weekStart,
    required this.days,
    required this.avgThisWeek,
    required this.streak,
    required this.mostFrequent,
  });

  @override
  List<Object?> get props => [weekStart, days, avgThisWeek, streak, mostFrequent];
}
