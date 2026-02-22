import 'package:equatable/equatable.dart';

class MoodEntity extends Equatable {
  final String id;
  final int mood; // 1-10
  final String? moodType;
  final String? note;
  final DateTime date;

  const MoodEntity({
    required this.id,
    required this.mood,
    required this.date,
    this.moodType,
    this.note,
  });

  @override
  List<Object?> get props => [id, mood, moodType, note, date];
}
