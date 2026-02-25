import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final checkDueRemindersUsecaseProvider = Provider<CheckDueRemindersUsecase>((ref) {
  return CheckDueRemindersUsecase(ref.read(reminderRepositoryProvider));
});

class CheckDueRemindersUsecase {
  final IReminderRepository _repo;

  CheckDueRemindersUsecase(this._repo);

  Future<Either<Failure, List<ReminderNotificationEntity>>> call({int windowMinutes = 2}) {
    return _repo.checkDueReminders(windowMinutes: windowMinutes);
  }
}
