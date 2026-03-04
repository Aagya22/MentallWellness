import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';

class ExerciseApiModel {
  final String id;
  final String type;
  final int duration;
  final String source;
  final DateTime date;
  final String? notes;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExerciseApiModel({
    required this.id,
    required this.type,
    required this.duration,
    required this.source,
    required this.date,
    this.notes,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseApiModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return ExerciseApiModel(
      id: (json['_id'] ?? json['id']).toString(),
      type: json['type']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? 'manual',
      date: parseDate(json['date']),
      notes: json['notes']?.toString(),
      category: json['category']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  ExerciseEntity toEntity() {
    return ExerciseEntity(
      id: id,
      type: type,
      duration: duration,
      source: source,
      date: date,
      notes: notes,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
