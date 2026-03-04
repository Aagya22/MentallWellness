import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final toggleReminderUsecaseProvider = Provider<ToggleReminderUsecase>((ref) {
  return ToggleReminderUsecase(ref.read(reminderRepositoryProvider));
});

class ToggleReminderUsecase {
  final IReminderRepository _repo;

  ToggleReminderUsecase(this._repo);

  Future<Either<Failure, ReminderEntity>> call({required String id}) {
    return _repo.toggleReminder(id: id);
  }
}
