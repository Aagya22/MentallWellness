import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';
import 'package:mentalwellness/features/schedule/domain/repositories/schedule_repository.dart';

final updateScheduleUsecaseProvider = Provider<UpdateScheduleUsecase>((ref) {
  return UpdateScheduleUsecase(ref.read(scheduleRepositoryProvider));
});

class UpdateScheduleUsecase {
  final IScheduleRepository _repo;

  UpdateScheduleUsecase(this._repo);

  Future<Either<Failure, ScheduleEntity>> call({
    required String id,
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) {
    return _repo.updateSchedule(
      id: id,
      title: title,
      date: date,
      time: time,
      description: description,
      location: location,
    );
  }
}
