import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/data/repositories/exercise_repository_impl.dart';
import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';
import 'package:mentalwellness/features/exercise/domain/repositories/exercise_repository.dart';

final getExercisesUsecaseProvider = Provider<GetExercisesUsecase>((ref) {
  return GetExercisesUsecase(ref.read(exerciseRepositoryProvider));
});

class GetExercisesUsecase {
  final IExerciseRepository _repo;

  GetExercisesUsecase(this._repo);

  Future<Either<Failure, List<ExerciseEntity>>> call() {
    return _repo.getExercises();
  }
}
