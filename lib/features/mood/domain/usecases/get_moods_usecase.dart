import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';

final getMoodsUsecaseProvider = Provider<GetMoodsUsecase>((ref) {
  return GetMoodsUsecase(ref.read(moodRepositoryProvider));
});

class GetMoodsUsecase {
  final IMoodRepository _repo;

  GetMoodsUsecase(this._repo);

  Future<Either<Failure, List<MoodEntity>>> call() {
    return _repo.getMoods();
  }
}
