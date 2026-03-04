import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';
import 'package:mentalwellness/features/schedule/domain/usecases/create_schedule_usecase.dart';
import 'package:mentalwellness/features/schedule/domain/usecases/delete_schedule_usecase.dart';
import 'package:mentalwellness/features/schedule/domain/usecases/get_schedules_usecase.dart';
import 'package:mentalwellness/features/schedule/domain/usecases/update_schedule_usecase.dart';
import 'package:mentalwellness/features/schedule/presentation/state/schedule_state.dart';

final scheduleViewModelProvider = NotifierProvider<ScheduleViewModel, ScheduleState>(
  ScheduleViewModel.new,
);

class ScheduleViewModel extends Notifier<ScheduleState> {
  late final GetSchedulesUsecase _get;
  late final CreateScheduleUsecase _create;
  late final UpdateScheduleUsecase _update;
  late final DeleteScheduleUsecase _delete;

  @override
  ScheduleState build() {
    _get = ref.read(getSchedulesUsecaseProvider);
    _create = ref.read(createScheduleUsecaseProvider);
    _update = ref.read(updateScheduleUsecaseProvider);
    _delete = ref.read(deleteScheduleUsecaseProvider);
    return const ScheduleState();
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  int _compareSchedule(ScheduleEntity a, ScheduleEntity b) {
    // Sort by date then time (HH:mm).
    final ad = a.date;
    final bd = b.date;
    final c = ad.compareTo(bd);
    if (c != 0) return c;
    final at = a.time;
    final bt = b.time;
    return at.compareTo(bt);
  }

  Future<void> _fetchRangeKeys({required String from, required String to}) async {
    state = state.copyWith(
      status: ScheduleStatus.loading,
      errorMessage: null,
      rangeFrom: from,
      rangeTo: to,
    );

    final res = await _get(from: from, to: to);
    res.fold(
      (f) => state = state.copyWith(
        status: ScheduleStatus.error,
        errorMessage: f.message,
      ),
      (list) {
        final next = [...list];
        next.sort(_compareSchedule);
        state = state.copyWith(
          status: ScheduleStatus.loaded,
          schedules: next,
        );
      },
    );
  }

  Future<void> fetchForDay(DateTime day) async {
    final key = _dateKey(day);
    await _fetchRangeKeys(from: key, to: key);
  }

  Future<void> fetchForRange({required DateTime from, required DateTime to}) async {
    await _fetchRangeKeys(from: _dateKey(from), to: _dateKey(to));
  }

  Future<void> refreshLastRange({required DateTime fallbackDay}) async {
    final from = state.rangeFrom;
    final to = state.rangeTo;
    if (from != null && to != null) {
      await _fetchRangeKeys(from: from, to: to);
      return;
    }
    await fetchForDay(fallbackDay);
  }

  Future<bool> createSchedule({
    required String title,
    required DateTime date,
    required String time,
    String? description,
    String? location,
  }) async {
    state = state.copyWith(status: ScheduleStatus.saving, errorMessage: null);
    final res = await _create(
      title: title,
      date: _dateKey(date),
      time: time,
      description: description,
      location: location,
    );

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ScheduleStatus.error, errorMessage: failure!.message);
      return false;
    }

    await refreshLastRange(fallbackDay: date);
    return true;
  }

  Future<bool> updateSchedule({
    required String id,
    required String title,
    required DateTime date,
    required String time,
    String? description,
    String? location,
  }) async {
    state = state.copyWith(status: ScheduleStatus.saving, errorMessage: null);
    final res = await _update(
      id: id,
      title: title,
      date: _dateKey(date),
      time: time,
      description: description,
      location: location,
    );

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ScheduleStatus.error, errorMessage: failure!.message);
      return false;
    }

    await refreshLastRange(fallbackDay: date);
    return true;
  }

  Future<bool> deleteSchedule({
    required String id,
    required DateTime dayToRefresh,
  }) async {
    state = state.copyWith(status: ScheduleStatus.saving, errorMessage: null);
    final res = await _delete(id: id);

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ScheduleStatus.error, errorMessage: failure!.message);
      return false;
    }

    await refreshLastRange(fallbackDay: dayToRefresh);
    return true;
  }
}
