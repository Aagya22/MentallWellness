import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:mentalwellness/features/reminder/presentation/state/reminder_state.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_viewmodel.dart';

class _FakeReminderRepository implements IReminderRepository {
  Either<Failure, List<ReminderEntity>> remindersResponse = const Right([]);
  Either<Failure, ReminderEntity> createResponse =
      const Left(ApiFailure(message: 'create not set'));
  Either<Failure, ReminderEntity> updateResponse =
      const Left(ApiFailure(message: 'update not set'));
  Either<Failure, Unit> deleteResponse =
      const Left(ApiFailure(message: 'delete not set'));
  Either<Failure, ReminderEntity> toggleResponse =
      const Left(ApiFailure(message: 'toggle not set'));

  int getRemindersCalls = 0;
  int createReminderCalls = 0;
  int updateReminderCalls = 0;
  int deleteReminderCalls = 0;
  int toggleReminderCalls = 0;

  @override
  Future<Either<Failure, List<ReminderEntity>>> getReminders() async {
    getRemindersCalls++;
    return remindersResponse;
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
    return createResponse;
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
    return updateResponse;
  }

  @override
  Future<Either<Failure, Unit>> deleteReminder({required String id}) async {
    deleteReminderCalls++;
    return deleteResponse;
  }

  @override
  Future<Either<Failure, ReminderEntity>> toggleReminder({required String id}) async {
    toggleReminderCalls++;
    return toggleResponse;
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
  ProviderContainer buildContainer(_FakeReminderRepository repository) {
    return ProviderContainer(
      overrides: [
        getRemindersUsecaseProvider.overrideWithValue(
          GetRemindersUsecase(repository),
        ),
        createReminderUsecaseProvider.overrideWithValue(
          CreateReminderUsecase(repository),
        ),
        updateReminderUsecaseProvider.overrideWithValue(
          UpdateReminderUsecase(repository),
        ),
        deleteReminderUsecaseProvider.overrideWithValue(
          DeleteReminderUsecase(repository),
        ),
        toggleReminderUsecaseProvider.overrideWithValue(
          ToggleReminderUsecase(repository),
        ),
      ],
    );
  }

  ReminderEntity buildReminder({required String id, bool enabled = true}) {
    final now = DateTime(2026, 3, 8, 10, 0);
    return ReminderEntity(
      id: id,
      title: 'Drink water',
      time: '10:00',
      type: 'exercise',
      daysOfWeek: const [1, 3, 5],
      enabled: enabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('starts with initial state', () {
    final repository = _FakeReminderRepository();
    final container = buildContainer(repository);

    final state = container.read(reminderViewModelProvider);

    expect(state.status, ReminderStatus.initial);
    expect(state.reminders, isEmpty);
    expect(state.errorMessage, isNull);

    container.dispose();
  });

  test('fetchReminders sets loaded state on success', () async {
    final repository = _FakeReminderRepository();
    final reminders = [buildReminder(id: 'r1')];
    repository.remindersResponse = Right(reminders);

    final container = buildContainer(repository);

    await container.read(reminderViewModelProvider.notifier).fetchReminders();

    final state = container.read(reminderViewModelProvider);
    expect(state.status, ReminderStatus.loaded);
    expect(state.reminders, reminders);
    expect(state.errorMessage, isNull);
    expect(repository.getRemindersCalls, 1);

    container.dispose();
  });

  test('fetchReminders sets error state on failure', () async {
    final repository = _FakeReminderRepository();
    repository.remindersResponse =
        const Left(ApiFailure(message: 'network failed'));

    final container = buildContainer(repository);

    await container.read(reminderViewModelProvider.notifier).fetchReminders();

    final state = container.read(reminderViewModelProvider);
    expect(state.status, ReminderStatus.error);
    expect(state.errorMessage, 'network failed');

    container.dispose();
  });

  test('createReminder returns true and refreshes reminders on success', () async {
    final repository = _FakeReminderRepository();
    final created = buildReminder(id: 'r2');
    final fetched = [created, buildReminder(id: 'r3')];
    repository.createResponse = Right(created);
    repository.remindersResponse = Right(fetched);

    final container = buildContainer(repository);

    final ok = await container.read(reminderViewModelProvider.notifier).createReminder(
          title: 'Hydrate',
          time: '09:00',
          type: 'exercise',
          daysOfWeek: const [1, 3, 5],
          enabled: true,
        );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isTrue);
    expect(state.status, ReminderStatus.loaded);
    expect(state.reminders, fetched);
    expect(repository.createReminderCalls, 1);
    expect(repository.getRemindersCalls, 1);

    container.dispose();
  });

  test('createReminder returns false and keeps error state on failure', () async {
    final repository = _FakeReminderRepository();
    repository.createResponse = const Left(ApiFailure(message: 'create failed'));

    final container = buildContainer(repository);

    final ok = await container.read(reminderViewModelProvider.notifier).createReminder(
          title: 'Hydrate',
          time: '09:00',
          type: 'exercise',
          daysOfWeek: const [1, 3, 5],
          enabled: true,
        );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isFalse);
    expect(state.status, ReminderStatus.error);
    expect(state.errorMessage, 'create failed');
    expect(repository.getRemindersCalls, 0);

    container.dispose();
  });

  test('updateReminder returns true and refreshes reminders on success', () async {
    final repository = _FakeReminderRepository();
    final updated = buildReminder(id: 'r4', enabled: false);
    final fetched = [updated];
    repository.updateResponse = Right(updated);
    repository.remindersResponse = Right(fetched);

    final container = buildContainer(repository);

    final ok = await container.read(reminderViewModelProvider.notifier).updateReminder(
          id: 'r4',
          title: 'Hydrate more',
          time: '11:00',
          type: 'exercise',
          daysOfWeek: const [2, 4],
          enabled: false,
        );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isTrue);
    expect(state.status, ReminderStatus.loaded);
    expect(state.reminders, fetched);

    container.dispose();
  });

  test('updateReminder returns false and sets error on failure', () async {
    final repository = _FakeReminderRepository();
    repository.updateResponse = const Left(ApiFailure(message: 'update failed'));

    final container = buildContainer(repository);

    final ok = await container.read(reminderViewModelProvider.notifier).updateReminder(
          id: 'r4',
          title: 'Hydrate more',
          time: '11:00',
          type: 'exercise',
          daysOfWeek: const [2, 4],
          enabled: false,
        );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isFalse);
    expect(state.status, ReminderStatus.error);
    expect(state.errorMessage, 'update failed');

    container.dispose();
  });

  test('deleteReminder returns true and refreshes reminders on success', () async {
    final repository = _FakeReminderRepository();
    repository.deleteResponse = const Right(unit);
    repository.remindersResponse = const Right([]);

    final container = buildContainer(repository);

    final ok =
        await container.read(reminderViewModelProvider.notifier).deleteReminder(
              id: 'r5',
            );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isTrue);
    expect(state.status, ReminderStatus.loaded);
    expect(state.reminders, isEmpty);

    container.dispose();
  });

  test('deleteReminder returns false and sets error on failure', () async {
    final repository = _FakeReminderRepository();
    repository.deleteResponse = const Left(ApiFailure(message: 'delete failed'));

    final container = buildContainer(repository);

    final ok =
        await container.read(reminderViewModelProvider.notifier).deleteReminder(
              id: 'r5',
            );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isFalse);
    expect(state.status, ReminderStatus.error);
    expect(state.errorMessage, 'delete failed');

    container.dispose();
  });

  test('toggleReminder returns true and refreshes reminders on success', () async {
    final repository = _FakeReminderRepository();
    final toggled = buildReminder(id: 'r6', enabled: false);
    final fetched = [toggled];
    repository.toggleResponse = Right(toggled);
    repository.remindersResponse = Right(fetched);

    final container = buildContainer(repository);

    final ok =
        await container.read(reminderViewModelProvider.notifier).toggleReminder(
              id: 'r6',
            );

    final state = container.read(reminderViewModelProvider);
    expect(ok, isTrue);
    expect(state.status, ReminderStatus.loaded);
    expect(state.reminders, fetched);

    container.dispose();
  });
}
