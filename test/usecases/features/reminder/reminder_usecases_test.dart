import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/delete_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/get_reminders_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/toggle_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/update_reminder_usecase.dart';

class _FakeReminderRepository implements IReminderRepository {
  Either<Failure, List<ReminderEntity>>? remindersResponse;
  Either<Failure, ReminderEntity>? createResponse;
  Either<Failure, ReminderEntity>? updateResponse;
  Either<Failure, Unit>? deleteResponse;
  Either<Failure, ReminderEntity>? toggleResponse;

  int getRemindersCalls = 0;
  int createReminderCalls = 0;
  int updateReminderCalls = 0;
  int deleteReminderCalls = 0;
  int toggleReminderCalls = 0;

  String? createTitle;
  String? createTime;
  String? createType;
  List<int>? createDays;
  bool? createEnabled;

  String? updateId;
  String? updateTitle;
  String? updateTime;
  String? updateType;
  List<int>? updateDays;
  bool? updateEnabled;

  String? deletedId;
  String? toggledId;

  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders() async {
    getRemindersCalls++;
    return remindersResponse ?? const Left(ApiFailure(message: 'reminders not set'));
  }

  @override
  Future<Either<Failure, ReminderEntity>> createReminder({
    required String title,
    required String time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    createReminderCalls++;
    createTitle = title;
    createTime = time;
    createType = type;
    createDays = daysOfWeek;
    createEnabled = enabled;
    return createResponse ?? const Left(ApiFailure(message: 'create not set'));
  }

  @override
  Future<Either<Failure, ReminderEntity>> updateReminder({
    required String id,
    String? title,
    String? time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    updateReminderCalls++;
    updateId = id;
    updateTitle = title;
    updateTime = time;
    updateType = type;
    updateDays = daysOfWeek;
    updateEnabled = enabled;
    return updateResponse ?? const Left(ApiFailure(message: 'update not set'));
  }

  @override
  Future<Either<Failure, Unit>> deleteReminder({required String id}) async {
    deleteReminderCalls++;
    deletedId = id;
    return deleteResponse ?? const Left(ApiFailure(message: 'delete not set'));
  }

  @override
  Future<Either<Failure, ReminderEntity>> toggleReminder({required String id}) async {
    toggleReminderCalls++;
    toggledId = id;
    return toggleResponse ?? const Left(ApiFailure(message: 'toggle not set'));
  }

  @override
  Future<Either<Failure, List<ReminderNotificationEntity>>> getNotificationHistory({
    int limit = 50,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, ReminderNotificationEntity>> markNotificationRead({
    required String id,
  }) async {
    return const Left(ApiFailure(message: 'not used in this test'));
  }

  @override
  Future<Either<Failure, int>> markAllNotificationsRead() async {
    return const Right(0);
  }

  @override
  Future<Either<Failure, int>> clearNotificationHistory() async {
    return const Right(0);
  }

  @override
  Future<Either<Failure, List<ReminderNotificationEntity>>> checkDueReminders({
    int windowMinutes = 10,
  }) async {
    return const Right([]);
  }
}

void main() {
  late _FakeReminderRepository repository;

  late GetRemindersUsecase getRemindersUsecase;
  late CreateReminderUsecase createReminderUsecase;
  late UpdateReminderUsecase updateReminderUsecase;
  late DeleteReminderUsecase deleteReminderUsecase;
  late ToggleReminderUsecase toggleReminderUsecase;

  setUp(() {
    repository = _FakeReminderRepository();
    getRemindersUsecase = GetRemindersUsecase(repository);
    createReminderUsecase = CreateReminderUsecase(repository);
    updateReminderUsecase = UpdateReminderUsecase(repository);
    deleteReminderUsecase = DeleteReminderUsecase(repository);
    toggleReminderUsecase = ToggleReminderUsecase(repository);
  });

  ReminderEntity buildReminder({required String id, bool enabled = true}) {
    final now = DateTime(2026, 3, 8, 9, 0);
    return ReminderEntity(
      id: id,
      title: 'Hydrate',
      time: '09:00',
      type: 'exercise',
      daysOfWeek: const [1, 3, 5],
      enabled: enabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('GetRemindersUsecase returns reminder list', () async {
    final list = [buildReminder(id: 'r1')];
    repository.remindersResponse = Right(list);

    final result = await getRemindersUsecase();

    expect(result, Right(list));
    expect(repository.getRemindersCalls, 1);
  });

  test('CreateReminderUsecase forwards all arguments', () async {
    final created = buildReminder(id: 'r2');
    repository.createResponse = Right(created);

    final result = await createReminderUsecase(
      title: 'Hydrate',
      time: '09:00',
      type: 'exercise',
      daysOfWeek: const [1, 3, 5],
      enabled: true,
    );

    expect(result, Right(created));
    expect(repository.createReminderCalls, 1);
    expect(repository.createTitle, 'Hydrate');
    expect(repository.createTime, '09:00');
    expect(repository.createType, 'exercise');
    expect(repository.createDays, const [1, 3, 5]);
    expect(repository.createEnabled, isTrue);
  });

  test('UpdateReminderUsecase forwards id and optional fields', () async {
    final updated = buildReminder(id: 'r3', enabled: false);
    repository.updateResponse = Right(updated);

    final result = await updateReminderUsecase(
      id: 'r3',
      title: 'Hydrate more',
      time: '10:30',
      type: 'exercise',
      daysOfWeek: const [2, 4, 6],
      enabled: false,
    );

    expect(result, Right(updated));
    expect(repository.updateReminderCalls, 1);
    expect(repository.updateId, 'r3');
    expect(repository.updateTitle, 'Hydrate more');
    expect(repository.updateTime, '10:30');
    expect(repository.updateType, 'exercise');
    expect(repository.updateDays, const [2, 4, 6]);
    expect(repository.updateEnabled, isFalse);
  });

  test('DeleteReminderUsecase forwards id and returns unit', () async {
    repository.deleteResponse = const Right(unit);

    final result = await deleteReminderUsecase(id: 'r4');

    expect(result, const Right(unit));
    expect(repository.deleteReminderCalls, 1);
    expect(repository.deletedId, 'r4');
  });

  test('ToggleReminderUsecase forwards id and returns updated reminder', () async {
    final toggled = buildReminder(id: 'r5', enabled: false);
    repository.toggleResponse = Right(toggled);

    final result = await toggleReminderUsecase(id: 'r5');

    expect(result, Right(toggled));
    expect(repository.toggleReminderCalls, 1);
    expect(repository.toggledId, 'r5');
  });
}
