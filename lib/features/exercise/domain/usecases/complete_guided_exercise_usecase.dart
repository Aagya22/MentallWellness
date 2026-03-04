import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';
import 'package:mentalwellness/features/exercise/data/repositories/exercise_repository_impl.dart';
import 'package:mentalwellness/features/exercise/domain/repositories/exercise_repository.dart';

final completeGuidedExerciseUsecaseProvider = Provider<CompleteGuidedExerciseUsecase>((ref) {
  return CompleteGuidedExerciseUsecase(ref.read(exerciseRepositoryProvider));
});

class CompleteGuidedExerciseUsecase {
  final IExerciseRepository _repository;

  CompleteGuidedExerciseUsecase(this._repository);

  Future<Either<Failure, ExerciseEntity>> call({
    required String title,
    required String category,
    required int plannedDurationSeconds,
    required int elapsedSeconds,
    DateTime? completedAt,
  }) {
    return _repository.completeGuidedExercise(
      title: title,
      category: category,
      plannedDurationSeconds: plannedDurationSeconds,
      elapsedSeconds: elapsedSeconds,
      completedAt: completedAt,
    );
  }
}
