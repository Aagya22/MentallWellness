import 'package:equatable/equatable.dart';

class ExerciseEntity extends Equatable {
  final String id;
  final String type;
  final int duration;
  final String source;
  final DateTime date;
  final String? notes;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExerciseEntity({
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

  @override
  List<Object?> get props => [
    id,
    type,
    duration,
    source,
    date,
    notes,
    category,
    createdAt,
    updatedAt,
  ];
}
