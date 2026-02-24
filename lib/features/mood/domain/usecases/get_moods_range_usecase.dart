import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_range_entity.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';

final getMoodsRangeUsecaseProvider = Provider<GetMoodsRangeUsecase>((ref) {
  return GetMoodsRangeUsecase(ref.read(moodRepositoryProvider));
});

class GetMoodsRangeUsecase {
  final IMoodRepository _repo;

  GetMoodsRangeUsecase(this._repo);

  Future<Either<Failure, List<MoodRangeEntity>>> call({
    required String from,
    required String to,
  }) {
    return _repo.getMoodsInRange(from: from, to: to);
  }
}
