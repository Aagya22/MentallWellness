import 'package:dartz/dartz.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';

abstract class IReminderRepository {
  Future<Either<Failure, List<ReminderEntity>>> getReminders();

  Future<Either<Failure, ReminderEntity>> createReminder({
    required String title,
    required String time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  });

  Future<Either<Failure, ReminderEntity>> updateReminder({
    required String id,
    String? title,
    String? time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  });

  Future<Either<Failure, Unit>> deleteReminder({required String id});

  Future<Either<Failure, ReminderEntity>> toggleReminder({required String id});

  // Notification history + due reminders
  Future<Either<Failure, List<ReminderNotificationEntity>>> getNotificationHistory({int limit});
  Future<Either<Failure, ReminderNotificationEntity>> markNotificationRead({required String id});
  Future<Either<Failure, int>> markAllNotificationsRead();
  Future<Either<Failure, int>> clearNotificationHistory();
  Future<Either<Failure, List<ReminderNotificationEntity>>> checkDueReminders({int windowMinutes});
}
