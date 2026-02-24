import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:mentalwellness/features/schedule/domain/repositories/schedule_repository.dart';

final deleteScheduleUsecaseProvider = Provider<DeleteScheduleUsecase>((ref) {
  return DeleteScheduleUsecase(ref.read(scheduleRepositoryProvider));
});

class DeleteScheduleUsecase {
  final IScheduleRepository _repo;

  DeleteScheduleUsecase(this._repo);

  Future<Either<Failure, Unit>> call({
    required String id,
  }) {
    return _repo.deleteSchedule(id: id);
  }
}
