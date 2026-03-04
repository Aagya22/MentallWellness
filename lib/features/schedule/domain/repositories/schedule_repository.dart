import 'package:dartz/dartz.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';

abstract interface class IScheduleRepository {
  Future<Either<Failure, List<ScheduleEntity>>> getSchedules({
    String? q,
    String? from,
    String? to,
  });

  Future<Either<Failure, ScheduleEntity>> createSchedule({
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  });

  Future<Either<Failure, ScheduleEntity>> updateSchedule({
    required String id,
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  });

  Future<Either<Failure, Unit>> deleteSchedule({
    required String id,
  });
}
