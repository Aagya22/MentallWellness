import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/core/services/notifications/local_notification_service_provider.dart';
import 'package:mentalwellness/core/services/storage/user_session_service.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/check_due_reminders_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/clear_notification_history_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/get_notification_history_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:mentalwellness/features/reminder/domain/usecases/mark_notification_read_usecase.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_notifications_state.dart';

final reminderNotificationsViewModelProvider =
    NotifierProvider<ReminderNotificationsViewModel, ReminderNotificationsState>(
  ReminderNotificationsViewModel.new,
);

class ReminderNotificationsViewModel extends Notifier<ReminderNotificationsState> {
  static const String _shownKey = 'shown_reminder_notification_ids';

  late final GetNotificationHistoryUsecase _getHistory;
  late final MarkNotificationReadUsecase _markRead;
  late final MarkAllNotificationsReadUsecase _markAllRead;
  late final ClearNotificationHistoryUsecase _clear;
  late final CheckDueRemindersUsecase _checkDue;

  @override
  ReminderNotificationsState build() {
    _getHistory = ref.read(getNotificationHistoryUsecaseProvider);
    _markRead = ref.read(markNotificationReadUsecaseProvider);
    _markAllRead = ref.read(markAllNotificationsReadUsecaseProvider);
    _clear = ref.read(clearNotificationHistoryUsecaseProvider);
    _checkDue = ref.read(checkDueRemindersUsecaseProvider);
    return const ReminderNotificationsState();
  }

  Set<String> _loadShownIds() {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList(_shownKey) ?? const <String>[];
    return list.toSet();
  }

  Future<void> _saveShownIds(Set<String> ids) async {
    final prefs = ref.read(sharedPreferencesProvider);
    // Keep the list bounded.
    final next = ids.toList();
    if (next.length > 120) {
      next.removeRange(0, next.length - 120);
    }
    await prefs.setStringList(_shownKey, next);
  }

  Future<void> _notifyNewlyDeliveredFromHistory(List<ReminderNotificationEntity> list) async {
    final now = DateTime.now();
    final shown = _loadShownIds();

    final candidates = <ReminderNotificationEntity>[];
    for (final n in list) {
      if (shown.contains(n.id)) continue;
      final age = now.difference(n.deliveredAt);
      if (age.isNegative) continue;
      if (age.inMinutes > 2) continue;
      candidates.add(n);
    }

    if (candidates.isEmpty) return;

   
    candidates.sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    final toShow = candidates.take(3);

    final notifier = ref.read(localNotificationServiceProvider);
    for (final n in toShow) {
      await notifier.showReminder(
        id: _stableId(n.id),
        title: 'Reminder',
        body: '${n.title} • ${_formatWhen(n.scheduledFor)}',
      );
      shown.add(n.id);
    }

    await _saveShownIds(shown);
  }

  Future<void> fetchHistory({int limit = 30}) async {
    state = state.copyWith(status: ReminderNotificationsStatus.loading, errorMessage: null);

    final res = await _getHistory(limit: limit);

    List<ReminderNotificationEntity>? list;
    Failure? failure;
    res.fold((f) => failure = f, (r) => list = r);

    if (failure != null) {
      state = state.copyWith(status: ReminderNotificationsStatus.error, errorMessage: failure!.message);
      return;
    }

    final items = list ?? const <ReminderNotificationEntity>[];
    state = state.copyWith(status: ReminderNotificationsStatus.loaded, notifications: items);
    await _notifyNewlyDeliveredFromHistory(items);
  }

  Future<void> markRead({required String id}) async {
    final current = state.notifications;
    final index = current.indexWhere((n) => n.id == id);
    if (index != -1 && current[index].readAt == null) {
      final updated = [...current];
      updated[index] = ReminderNotificationEntity(
        id: current[index].id,
        reminderId: current[index].reminderId,
        title: current[index].title,
        type: current[index].type,
        scheduledFor: current[index].scheduledFor,
        deliveredAt: current[index].deliveredAt,
        readAt: DateTime.now(),
      );
      state = state.copyWith(notifications: updated);
    }

    final res = await _markRead(id: id);
    res.fold(
      (f) => state = state.copyWith(status: ReminderNotificationsStatus.error, errorMessage: f.message),
      (_) {},
    );
  }

  Future<bool> markAllRead() async {
    final now = DateTime.now();
    final current = state.notifications;
    if (current.any((n) => !n.isRead)) {
      final updated = current
          .map(
            (n) => n.isRead
                ? n
                : ReminderNotificationEntity(
                    id: n.id,
                    reminderId: n.reminderId,
                    title: n.title,
                    type: n.type,
                    scheduledFor: n.scheduledFor,
                    deliveredAt: n.deliveredAt,
                    readAt: now,
                  ),
          )
          .toList();
      state = state.copyWith(notifications: updated);
    }

    state = state.copyWith(status: ReminderNotificationsStatus.saving, errorMessage: null);

    final res = await _markAllRead();
    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ReminderNotificationsStatus.error, errorMessage: failure!.message);
      return false;
    }

    await fetchHistory();
    return true;
  }

  Future<bool> clearAll() async {
    state = state.copyWith(status: ReminderNotificationsStatus.saving, errorMessage: null);

    final res = await _clear();

    Failure? failure;
    res.fold((f) => failure = f, (_) {});
    if (failure != null) {
      state = state.copyWith(status: ReminderNotificationsStatus.error, errorMessage: failure!.message);
      return false;
    }

    await fetchHistory();
    return true;
  }

  int _stableId(String s) {
    var hash = 0;
    for (final codeUnit in s.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash & 0x7fffffff;
  }

  String _formatWhen(DateTime dt) {
    // Example: Tue, Feb 24 • 7:30 AM
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  Future<void> checkDueAndNotify({int windowMinutes = 2}) async {
    final res = await _checkDue(windowMinutes: windowMinutes);

    List<ReminderNotificationEntity>? delivered;
    Failure? failure;
    res.fold((f) => failure = f, (list) => delivered = list);
    if (failure != null) {
      state = state.copyWith(status: ReminderNotificationsStatus.error, errorMessage: failure!.message);
      return;
    }

    if (delivered == null || delivered!.isEmpty) {
      return;
    }

    final shown = _loadShownIds();
    final notifier = ref.read(localNotificationServiceProvider);
    for (final n in delivered!) {
      if (shown.contains(n.id)) continue;
      await notifier.showReminder(
        id: _stableId(n.id),
        title: 'Reminder',
        body: '${n.title} • ${_formatWhen(n.scheduledFor)}',
      );
      shown.add(n.id);
    }

    await _saveShownIds(shown);

    await fetchHistory();
  }
}
