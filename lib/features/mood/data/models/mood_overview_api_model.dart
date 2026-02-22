import 'package:mentalwellness/features/mood/data/models/mood_api_model.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';

class MoodOverviewApiModel {
  final DateTime weekStart;
  final List<MoodOverviewDayEntity> days;
  final MoodAverageEntity? avgThisWeek;
  final int streak;
  final MoodMostFrequentEntity? mostFrequent;

  MoodOverviewApiModel({
    required this.weekStart,
    required this.days,
    required this.avgThisWeek,
    required this.streak,
    required this.mostFrequent,
  });

  factory MoodOverviewApiModel.fromJson(Map<String, dynamic> json) {
    final weekStart = DateTime.parse(json['weekStart'] as String);
    final daysJson = (json['days'] as List).cast<dynamic>();

    MoodAverageEntity? avg;
    final avgJson = json['avgThisWeek'];
    if (avgJson is Map<String, dynamic>) {
      avg = MoodAverageEntity(
        score: (avgJson['score'] as num).toDouble(),
        label: (avgJson['label'] as String?) ?? '',
      );
    }

    MoodMostFrequentEntity? most;
    final mostJson = json['mostFrequent'];
    if (mostJson is Map<String, dynamic>) {
      most = MoodMostFrequentEntity(
        key: (mostJson['key'] as String?) ?? '',
        count: (mostJson['count'] as num?)?.toInt() ?? 0,
      );
    }

    final days = daysJson.map((e) {
      final m = e as Map<String, dynamic>;
      final date = DateTime.parse(m['date'] as String);
      final entryJson = m['entry'];
      return MoodOverviewDayEntity(
        date: date,
        entry: entryJson is Map<String, dynamic>
            ? MoodApiModel.fromJson(entryJson).toEntity()
            : null,
      );
    }).toList();

    return MoodOverviewApiModel(
      weekStart: weekStart,
      days: days,
      avgThisWeek: avg,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      mostFrequent: most,
    );
  }

  MoodOverviewEntity toEntity() {
    return MoodOverviewEntity(
      weekStart: weekStart,
      days: days,
      avgThisWeek: avgThisWeek,
      streak: streak,
      mostFrequent: mostFrequent,
    );
  }
}
