import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:mentalwellness/features/mood/domain/repositories/mood_repository.dart';

final deleteMoodUsecaseProvider = Provider<DeleteMoodUsecase>((ref) {
  return DeleteMoodUsecase(ref.read(moodRepositoryProvider));
});

class DeleteMoodUsecase {
  final IMoodRepository _repo;

  DeleteMoodUsecase(this._repo);

  Future<Either<Failure, bool>> call({required String id}) {
    return _repo.deleteMood(id: id);
  }
}
