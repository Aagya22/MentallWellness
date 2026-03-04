import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/data/repositories/exercise_repository_impl.dart';
import 'package:mentalwellness/features/exercise/domain/entities/guided_history_entity.dart';
import 'package:mentalwellness/features/exercise/domain/repositories/exercise_repository.dart';

final getGuidedHistoryUsecaseProvider = Provider<GetGuidedHistoryUsecase>((ref) {
  return GetGuidedHistoryUsecase(ref.read(exerciseRepositoryProvider));
});

class GetGuidedHistoryUsecase {
  final IExerciseRepository _repository;

  GetGuidedHistoryUsecase(this._repository);

  Future<Either<Failure, List<GuidedHistoryDayEntity>>> call({
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getGuidedHistory(from: from, to: to);
  }
}
