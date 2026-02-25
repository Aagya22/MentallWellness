import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final deleteReminderUsecaseProvider = Provider<DeleteReminderUsecase>((ref) {
  return DeleteReminderUsecase(ref.read(reminderRepositoryProvider));
});

class DeleteReminderUsecase {
  final IReminderRepository _repo;

  DeleteReminderUsecase(this._repo);

  Future<Either<Failure, Unit>> call({required String id}) {
    return _repo.deleteReminder(id: id);
  }
}
