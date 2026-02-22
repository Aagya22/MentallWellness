import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';

final createMoodUsecaseProvider = Provider<CreateMoodUsecase>((ref) {
  return CreateMoodUsecase(ref.read(moodRepositoryProvider));
});

class CreateMoodUsecase {
  final IMoodRepository _repo;

  CreateMoodUsecase(this._repo);

  Future<Either<Failure, MoodEntity>> call({
    required int mood,
    String? moodType,
    String? note,
    DateTime? date,
  }) {
    return _repo.createMood(mood: mood, moodType: moodType, note: note, date: date);
  }
}
