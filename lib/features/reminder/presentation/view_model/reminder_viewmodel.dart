import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/delete_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/get_reminders_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/toggle_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/update_reminder_usecase.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_state.dart';

final reminderViewModelProvider = NotifierProvider<ReminderViewModel, ReminderState>(
  ReminderViewModel.new,
);

class ReminderViewModel extends Notifier<ReminderState> {
  late final GetRemindersUsecase _get;
  late final CreateReminderUsecase _create;
  late final UpdateReminderUsecase _update;
  late final DeleteReminderUsecase _delete;
  late final ToggleReminderUsecase _toggle;

  @override
  ReminderState build() {
    _get = ref.read(getRemindersUsecaseProvider);
    _create = ref.read(createReminderUsecaseProvider);
    _update = ref.read(updateReminderUsecaseProvider);
    _delete = ref.read(deleteReminderUsecaseProvider);
    _toggle = ref.read(toggleReminderUsecaseProvider);
    return const ReminderState();
  }

  Future<void> fetchReminders() async {
    state = state.copyWith(status: ReminderStatus.loading, errorMessage: null);

    final res = await _get();
    res.fold(
      (f) => state = state.copyWith(status: ReminderStatus.error, errorMessage: f.message),
      (list) => state = state.copyWith(status: ReminderStatus.loaded, reminders: list),
    );
  }

  Future<bool> createReminder({
    required String title,
    required String time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    state = state.copyWith(status: ReminderStatus.saving, errorMessage: null);

    final res = await _create(
      title: title,
      time: time,
      type: type,
      daysOfWeek: daysOfWeek,
      enabled: enabled,
    );

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: failure!.message);
      return false;
    }

    await fetchReminders();
    return true;
  }

  Future<bool> updateReminder({
    required String id,
    String? title,
    String? time,
    String? type,
    List<int>? daysOfWeek,
    bool? enabled,
  }) async {
    state = state.copyWith(status: ReminderStatus.saving, errorMessage: null);

    final res = await _update(
      id: id,
      title: title,
      time: time,
      type: type,
      daysOfWeek: daysOfWeek,
      enabled: enabled,
    );

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: failure!.message);
      return false;
    }

    await fetchReminders();
    return true;
  }

  Future<bool> deleteReminder({required String id}) async {
    state = state.copyWith(status: ReminderStatus.saving, errorMessage: null);

    final res = await _delete(id: id);

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: failure!.message);
      return false;
    }

    await fetchReminders();
    return true;
  }

  Future<bool> toggleReminder({required String id}) async {
    state = state.copyWith(status: ReminderStatus.saving, errorMessage: null);

    final res = await _toggle(id: id);

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: failure!.message);
      return false;
    }

    await fetchReminders();
    return true;
  }
}
