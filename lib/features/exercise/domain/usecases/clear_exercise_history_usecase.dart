import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/data/repositories/exercise_repository_impl.dart';
import 'package:mentalwellness/features/exercise/domain/repositories/exercise_repository.dart';

final clearExerciseHistoryUsecaseProvider =
    Provider<ClearExerciseHistoryUsecase>((ref) {
      return ClearExerciseHistoryUsecase(ref.read(exerciseRepositoryProvider));
    });

class ClearExerciseHistoryUsecase {
  final IExerciseRepository _repo;

  ClearExerciseHistoryUsecase(this._repo);

  Future<Either<Failure, int>> call() {
    return _repo.clearExerciseHistory();
  }
}
