import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';

class MoodApiModel {
  final String? id;
  final int mood;
  final String? moodType;
  final String? note;
  final DateTime date;

  MoodApiModel({
    this.id,
    required this.mood,
    required this.date,
    this.moodType,
    this.note,
  });

  factory MoodApiModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id']) as String?;
    return MoodApiModel(
      id: rawId,
      mood: (json['mood'] as num).toInt(),
      moodType: json['moodType'] as String?,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  MoodEntity toEntity() {
    return MoodEntity(
      id: id ?? '',
      mood: mood,
      moodType: moodType,
      note: note,
      date: date,
    );
  }
}
