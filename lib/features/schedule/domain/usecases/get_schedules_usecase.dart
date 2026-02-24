import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';
import 'package:mentalwellness/features/schedule/domain/repositories/schedule_repository.dart';

final getSchedulesUsecaseProvider = Provider<GetSchedulesUsecase>((ref) {
  return GetSchedulesUsecase(ref.read(scheduleRepositoryProvider));
});

class GetSchedulesUsecase {
  final IScheduleRepository _repo;

  GetSchedulesUsecase(this._repo);

  Future<Either<Failure, List<ScheduleEntity>>> call({
    String? q,
    String? from,
    String? to,
  }) {
    return _repo.getSchedules(q: q, from: from, to: to);
  }
}
