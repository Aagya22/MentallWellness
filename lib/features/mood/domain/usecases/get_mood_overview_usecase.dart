import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';

final getMoodOverviewUsecaseProvider = Provider<GetMoodOverviewUsecase>((ref) {
  return GetMoodOverviewUsecase(ref.read(moodRepositoryProvider));
});

class GetMoodOverviewUsecase {
  final IMoodRepository _repo;

  GetMoodOverviewUsecase(this._repo);

  Future<Either<Failure, MoodOverviewEntity>> call() {
    return _repo.getOverview();
  }
}
