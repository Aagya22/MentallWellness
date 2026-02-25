import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final updateReminderUsecaseProvider = Provider<UpdateReminderUsecase>((ref) {
  return UpdateReminderUsecase(ref.read(reminderRepositoryProvider));
});

class UpdateReminderUsecase {
  final IReminderRepository _repo;

  UpdateReminderUsecase(this._repo);

  Future<Either<Failure, ReminderEntity>> call({
    required String id,
    String? title,
    String? time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) {
    return _repo.updateReminder(
      id: id,
      title: title,
      time: time,
      type: type,
      daysOfWeek: daysOfWeek,
      enabled: enabled,
    );
  }
}
