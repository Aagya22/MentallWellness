import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final markNotificationReadUsecaseProvider = Provider<MarkNotificationReadUsecase>((ref) {
  return MarkNotificationReadUsecase(ref.read(reminderRepositoryProvider));
});

class MarkNotificationReadUsecase {
  final IReminderRepository _repo;

  MarkNotificationReadUsecase(this._repo);

  Future<Either<Failure, ReminderNotificationEntity>> call({required String id}) {
    return _repo.markNotificationRead(id: id);
  }
}
