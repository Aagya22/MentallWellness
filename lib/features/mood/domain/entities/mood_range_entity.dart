import 'package:equatable/equatable.dart';

class MoodRangeEntity extends Equatable {
  final String id;
  final String dayKey; // YYYY-MM-DD (local day)
  final int mood;
  final String? moodType;
  final String? note;
  final DateTime date;

  const MoodRangeEntity({
    required this.id,
    required this.dayKey,
    required this.mood,
    required this.date,
    this.moodType,
    this.note,
  });

  @override
  List<Object?> get props => [id, dayKey, mood, moodType, note, date];
}
