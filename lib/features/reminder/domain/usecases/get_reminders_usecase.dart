import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final getRemindersUsecaseProvider = Provider<GetRemindersUsecase>((ref) {
  return GetRemindersUsecase(ref.read(reminderRepositoryProvider));
});

class GetRemindersUsecase {
  final IReminderRepository _repo;

  GetRemindersUsecase(this._repo);

  Future<Either<Failure, List<ReminderEntity>>> call() {
    return _repo.getReminders();
  }
}
