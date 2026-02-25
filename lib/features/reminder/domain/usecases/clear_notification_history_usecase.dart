import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/data/repositories/reminder_repository_impl.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';

final clearNotificationHistoryUsecaseProvider = Provider<ClearNotificationHistoryUsecase>((ref) {
  return ClearNotificationHistoryUsecase(ref.read(reminderRepositoryProvider));
});

class ClearNotificationHistoryUsecase {
  final IReminderRepository _repo;

  ClearNotificationHistoryUsecase(this._repo);

  Future<Either<Failure, int>> call() {
    return _repo.clearNotificationHistory();
  }
}
