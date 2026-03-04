import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';
import 'package:mentalwellness/features/schedule/domain/repositories/schedule_repository.dart';

final createScheduleUsecaseProvider = Provider<CreateScheduleUsecase>((ref) {
  return CreateScheduleUsecase(ref.read(scheduleRepositoryProvider));
});

class CreateScheduleUsecase {
  final IScheduleRepository _repo;

  CreateScheduleUsecase(this._repo);

  Future<Either<Failure, ScheduleEntity>> call({
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) {
    return _repo.createSchedule(
      title: title,
      date: date,
      time: time,
      description: description,
      location: location,
    );
  }
}
