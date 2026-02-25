import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final getNotificationHistoryUsecaseProvider = Provider<GetNotificationHistoryUsecase>((ref) {
  return GetNotificationHistoryUsecase(ref.read(reminderRepositoryProvider));
});

class GetNotificationHistoryUsecase {
  final IReminderRepository _repo;

  GetNotificationHistoryUsecase(this._repo);

  Future<Either<Failure, List<ReminderNotificationEntity>>> call({int limit = 20}) {
    return _repo.getNotificationHistory(limit: limit);
  }
}
