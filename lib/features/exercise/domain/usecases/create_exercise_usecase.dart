import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/data/repositories/exercise_repository_impl.dart';
import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';
import 'package:mentalwellness/features/exercise/domain/repositories/exercise_repository.dart';

final createExerciseUsecaseProvider = Provider<CreateExerciseUsecase>((ref) {
  return CreateExerciseUsecase(ref.read(exerciseRepositoryProvider));
});

class CreateExerciseUsecase {
  final IExerciseRepository _repo;

  CreateExerciseUsecase(this._repo);

  Future<Either<Failure, ExerciseEntity>> call({
    required String type,
    required int duration,
    DateTime? date,
    String? notes,
  }) {
    return _repo.createExercise(
      type: type,
      duration: duration,
      date: date,
      notes: notes,
    );
  }
}
