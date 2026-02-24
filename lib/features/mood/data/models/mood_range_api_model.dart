import 'package:mentalwellness/features/mood/domain/entities/mood_range_entity.dart';

class MoodRangeApiModel {
  final String? id;
  final String dayKey;
  final int mood;
  final String? moodType;
  final String? note;
  final DateTime date;

  MoodRangeApiModel({
    this.id,
    required this.dayKey,
    required this.mood,
    required this.date,
    this.moodType,
    this.note,
  });

  factory MoodRangeApiModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id']) as String?;
    return MoodRangeApiModel(
      id: rawId,
      dayKey: (json['dayKey'] as String?) ?? '',
      mood: (json['mood'] as num).toInt(),
      moodType: json['moodType'] as String?,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  MoodRangeEntity toEntity() {
    return MoodRangeEntity(
      id: id ?? '',
      dayKey: dayKey,
      mood: mood,
      moodType: moodType,
      note: note,
      date: date,
    );
  }
}
