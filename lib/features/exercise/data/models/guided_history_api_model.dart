import 'package:mentalwellness/features/exercise/domain/entities/guided_history_entity.dart';

class GuidedHistorySessionApiModel {
  final String id;
  final String title;
  final String? category;
  final int duration;
  final int? durationSeconds;
  final DateTime date;

  const GuidedHistorySessionApiModel({
    required this.id,
    required this.title,
    this.category,
    required this.duration,
    this.durationSeconds,
    required this.date,
  });

  factory GuidedHistorySessionApiModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return GuidedHistorySessionApiModel(
      id: (json['_id'] ?? json['id']).toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString(),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      date: parseDate(json['date']),
    );
  }

  GuidedHistorySessionEntity toEntity() {
    return GuidedHistorySessionEntity(
      id: id,
      title: title,
      category: category,
      duration: duration,
      durationSeconds: durationSeconds,
      date: date,
    );
  }
}

class GuidedHistoryDayApiModel {
  final String date;
  final int totalMinutes;
  final List<GuidedHistorySessionApiModel> sessions;

  const GuidedHistoryDayApiModel({
    required this.date,
    required this.totalMinutes,
    required this.sessions,
  });

  factory GuidedHistoryDayApiModel.fromJson(Map<String, dynamic> json) {
    final sessionsJson = (json['sessions'] as List?)?.cast<dynamic>() ?? const [];
    return GuidedHistoryDayApiModel(
      date: json['date']?.toString() ?? '',
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      sessions: sessionsJson
          .map((e) => GuidedHistorySessionApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  GuidedHistoryDayEntity toEntity() {
    return GuidedHistoryDayEntity(
      date: date,
      totalMinutes: totalMinutes,
      sessions: sessions.map((s) => s.toEntity()).toList(),
    );
  }
}
