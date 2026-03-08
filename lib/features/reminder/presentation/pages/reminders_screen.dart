import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/services/notifications/local_notification_service_provider.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_notifications_state.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_state.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_notifications_viewmodel.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_viewmodel.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(localNotificationServiceProvider).init();
      await ref.read(reminderViewModelProvider.notifier).fetchReminders();
      await ref
          .read(reminderNotificationsViewModelProvider.notifier)
          .fetchHistory();
    });
  }

  Future<void> _refreshCurrentTab(int tabIndex) async {
    if (tabIndex == 0) {
      await ref.read(reminderViewModelProvider.notifier).fetchReminders();
      return;
    }

    await ref
        .read(reminderNotificationsViewModelProvider.notifier)
        .fetchHistory();
  }

  Future<void> _markAllNotificationsRead() async {
    final ok = await ref
        .read(reminderNotificationsViewModelProvider.notifier)
        .markAllRead();
    if (!mounted) return;

    showMySnackBar(
      context: context,
      message: ok
          ? 'All notifications marked as read'
          : 'Failed to mark all read',
      color: ok ? null : Colors.red,
    );
  }

  Future<void> _clearNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear notification history?'),
        content: const Text('This will remove all reminder notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await ref
        .read(reminderNotificationsViewModelProvider.notifier)
        .clearAll();
    if (!mounted) return;

    showMySnackBar(
      context: context,
      message: ok ? 'Notification history cleared' : 'Failed to clear history',
      color: ok ? null : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminderState = ref.watch(reminderViewModelProvider);
    final notificationState = ref.watch(reminderNotificationsViewModelProvider);

    final showSaving = reminderState.status == ReminderStatus.saving;
    final showNotifSaving =
        notificationState.status == ReminderNotificationsStatus.saving;
    final savingAny = showSaving || showNotifSaving;

    ref.listen(reminderViewModelProvider, (prev, next) {
      final prevMsg = prev?.errorMessage;
      final nextMsg = next.errorMessage;
      if (nextMsg != null && nextMsg.isNotEmpty && nextMsg != prevMsg) {
        showMySnackBar(context: context, message: nextMsg, color: Colors.red);
      }
    });

    ref.listen(reminderNotificationsViewModelProvider, (prev, next) {
      final prevMsg = prev?.errorMessage;
      final nextMsg = next.errorMessage;
      if (nextMsg != null && nextMsg.isNotEmpty && nextMsg != prevMsg) {
        showMySnackBar(context: context, message: nextMsg, color: Colors.red);
      }
    });

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final tabIndex = controller.index;

              return Scaffold(
                backgroundColor: const Color(0xFFF4F1EA),
                appBar: AppBar(
                  backgroundColor: const Color(0xFFF4F1EA),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  iconTheme: const IconThemeData(color: Color(0xFF1F2A22)),
                  titleSpacing: 16,
                  title: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminders',
                        style: TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 21,
                          color: Color(0xFF1F2A22),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Stay consistent with your wellness habits',
                        style: TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 11,
                          color: Color(0xFF5D6A62),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: savingAny
                          ? null
                          : () => _refreshCurrentTab(tabIndex),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF2D5A44),
                      ),
                      tooltip: 'Refresh',
                    ),
                    if (tabIndex == 1)
                      IconButton(
                        onPressed: savingAny ? null : _markAllNotificationsRead,
                        icon: const Icon(
                          Icons.done_all_rounded,
                          color: Color(0xFF2D5A44),
                        ),
                        tooltip: 'Mark all read',
                      ),
                    if (tabIndex == 1)
                      IconButton(
                        onPressed: savingAny ? null : _clearNotifications,
                        icon: const Icon(
                          Icons.delete_sweep_outlined,
                          color: Color(0xFF8B2E2E),
                        ),
                        tooltip: 'Clear history',
                      ),
                    const SizedBox(width: 4),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(62),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6ECE7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Color(0xFF1F2A22),
                          unselectedLabelColor: Color(0xFF637066),
                          labelStyle: TextStyle(
                            fontFamily: 'Inter Bold',
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 13,
                          ),
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          tabs: [
                            Tab(text: 'Reminders'),
                            Tab(text: 'Notifications'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                floatingActionButton: tabIndex == 0
                    ? FloatingActionButton.extended(
                        onPressed: showSaving
                            ? null
                            : () async {
                                await showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const _UpsertReminderSheet(),
                                );
                              },
                        backgroundColor: const Color(0xFF2D5A44),
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'New reminder',
                          style: TextStyle(fontFamily: 'Inter Medium'),
                        ),
                      )
                    : null,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 900;

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 980 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            if (savingAny)
                              const LinearProgressIndicator(
                                minHeight: 2,
                                color: Color(0xFF2D5A44),
                                backgroundColor: Color(0xFFEAF1ED),
                              ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _RemindersBody(state: reminderState),
                                  _NotificationsBody(state: notificationState),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RemindersBody extends ConsumerWidget {
  const _RemindersBody({required this.state});

  final ReminderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.status == ReminderStatus.loading && state.reminders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5A44)),
      );
    }

    final saving = state.status == ReminderStatus.saving;
    final reminders = state.reminders;
    final enabledCount = reminders.where((r) => r.enabled).length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _DualMetricCard(
              leftLabel: 'Active',
              leftValue: enabledCount.toString(),
              rightLabel: 'Total',
              rightValue: reminders.length.toString(),
            ),
          ),
        ),
        if (reminders.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyStateCard(
              icon: Icons.alarm_off_rounded,
              title: 'No reminders yet',
              subtitle:
                  'Tap "New reminder" to schedule your first wellness check-in.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final reminder = reminders[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == reminders.length - 1 ? 0 : 10,
                  ),
                  child: _ReminderCard(
                    reminder: reminder,
                    disabled: saving,
                    onTap: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _UpsertReminderSheet(initial: reminder),
                      );
                    },
                    onToggleEnabled: saving
                        ? null
                        : (value) async {
                            final ok = await ref
                                .read(reminderViewModelProvider.notifier)
                                .updateReminder(
                                  id: reminder.id,
                                  enabled: value,
                                );
                            if (!ok && context.mounted) {
                              showMySnackBar(
                                context: context,
                                message: 'Failed to update reminder',
                                color: Colors.red,
                              );
                            }
                          },
                    onDelete: saving
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete reminder?'),
                                content: Text(
                                  '"${reminder.title}" will be removed.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true || !context.mounted) return;

                            final ok = await ref
                                .read(reminderViewModelProvider.notifier)
                                .deleteReminder(id: reminder.id);
                            if (ok && context.mounted) {
                              showMySnackBar(
                                context: context,
                                message: 'Reminder deleted',
                              );
                            }
                          },
                  ),
                );
              }, childCount: reminders.length),
            ),
          ),
      ],
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.state});

  final ReminderNotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.status == ReminderNotificationsStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5A44)),
      );
    }

    final notifications = state.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final saving = state.status == ReminderNotificationsStatus.saving;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _DualMetricCard(
              leftLabel: 'Unread',
              leftValue: unreadCount.toString(),
              rightLabel: 'Total',
              rightValue: notifications.length.toString(),
            ),
          ),
        ),
        if (notifications.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyStateCard(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'Delivered reminder alerts will appear here.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = notifications[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == notifications.length - 1 ? 0 : 10,
                  ),
                  child: _NotificationCard(
                    notification: item,
                    disabled: saving,
                    onTap: () {
                      if (!item.isRead) {
                        ref
                            .read(
                              reminderNotificationsViewModelProvider.notifier,
                            )
                            .markRead(id: item.id);
                      }
                    },
                    onMarkRead: item.isRead
                        ? null
                        : () {
                            ref
                                .read(
                                  reminderNotificationsViewModelProvider
                                      .notifier,
                                )
                                .markRead(id: item.id);
                          },
                  ),
                );
              }, childCount: notifications.length),
            ),
          ),
      ],
    );
  }
}

class _DualMetricCard extends StatelessWidget {
  const _DualMetricCard({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5A44), Color(0xFF4E7A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x291F2A22),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(label: leftLabel, value: leftValue),
          ),
          Container(width: 1, height: 30, color: const Color(0x66FFFFFF)),
          Expanded(
            child: _MetricItem(label: rightLabel, value: rightValue),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter Medium',
            fontSize: 12,
            color: Color(0xFFE9F1EC),
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onDelete,
    required this.onToggleEnabled,
    required this.disabled,
  });

  final ReminderEntity reminder;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleEnabled;
  final bool disabled;

  String _formatTime(BuildContext context, String hhmm) {
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(hhmm.trim());
    if (m == null) return hhmm;
    final hh = int.tryParse(m.group(1)!) ?? 0;
    final mm = int.tryParse(m.group(2)!) ?? 0;
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return hhmm;
    final tod = TimeOfDay(hour: hh, minute: mm);
    return MaterialLocalizations.of(context).formatTimeOfDay(tod);
  }

  String _typeLabel(String type) {
    final t = type.trim().isEmpty ? 'journal' : type.trim();
    return t[0].toUpperCase() + t.substring(1);
  }

  IconData _typeIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'mood':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'journal':
      default:
        return Icons.menu_book_rounded;
    }
  }

  List<int> _normalizedDays(List<int> days) {
    final unique = {...days.where((d) => d >= 0 && d <= 6)}.toList()..sort();
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final days = _normalizedDays(reminder.daysOfWeek);
    final isEveryday = days.length == 7;
    final enabled = reminder.enabled;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF7F8F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled ? const Color(0xFFD8E5DD) : const Color(0xFFE1E8E3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _typeIcon(reminder.type),
                    color: const Color(0xFF2D5A44),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 15,
                          color: Color(0xFF1F2A22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatTime(context, reminder.time)} • ${_typeLabel(reminder.type)}',
                        style: const TextStyle(
                          fontFamily: 'Inter Medium',
                          fontSize: 12,
                          color: Color(0xFF5D6A62),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: disabled ? null : onToggleEnabled,
                  activeColor: const Color(0xFF2D5A44),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? const Color(0xFF2D5A44)
                        : const Color(0xFFD8E3DC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    enabled ? 'Enabled' : 'Paused',
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 11,
                      color: enabled ? Colors.white : const Color(0xFF2D5A44),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: disabled ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B2E2E),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 12,
                    ),
                    minimumSize: const Size(0, 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: isEveryday
                    ? const [_DayPill(label: 'Everyday')]
                    : days
                          .map((day) => _DayPill(label: dayLabels[day]))
                          .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.disabled,
  });

  final ReminderNotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;
  final bool disabled;

  String _typeLabel(String type) {
    final t = type.trim().isEmpty ? 'journal' : type.trim();
    return t[0].toUpperCase() + t.substring(1);
  }

  IconData _typeIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'mood':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'journal':
      default:
        return Icons.menu_book_rounded;
    }
  }

  String _whenLabel(DateTime dt) {
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: unread ? Colors.white : const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unread ? const Color(0xFFBFD3C7) : const Color(0xFFE1E8E3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: unread
                    ? const Color(0xFFEAF1ED)
                    : const Color(0xFFEDEFEF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _typeIcon(notification.type),
                color: const Color(0xFF2D5A44),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: unread ? 'Inter Bold' : 'Inter Medium',
                      fontSize: 14,
                      color: const Color(0xFF1F2A22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_typeLabel(notification.type)} • ${_whenLabel(notification.deliveredAt)}',
                    style: const TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      color: Color(0xFF5D6A62),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: unread
                              ? const Color(0xFF2D5A44)
                              : const Color(0xFFD8E3DC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unread ? 'Unread' : 'Read',
                          style: TextStyle(
                            fontFamily: 'Inter Medium',
                            fontSize: 11,
                            color: unread
                                ? Colors.white
                                : const Color(0xFF2D5A44),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (unread)
                        TextButton.icon(
                          onPressed: disabled ? null : onMarkRead,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Mark read'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2D5A44),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter Medium',
                              fontSize: 12,
                            ),
                            minimumSize: const Size(0, 28),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter Medium',
          fontSize: 11,
          color: Color(0xFF2D5A44),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EEE9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 34, color: const Color(0xFF2D5A44)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 16,
              color: Color(0xFF1F2A22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 13,
              color: Color(0xFF5D6A62),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpsertReminderSheet extends ConsumerStatefulWidget {
  const _UpsertReminderSheet({this.initial});

  final ReminderEntity? initial;

  @override
  ConsumerState<_UpsertReminderSheet> createState() =>
      _UpsertReminderSheetState();
}

class _UpsertReminderSheetState extends ConsumerState<_UpsertReminderSheet> {
  late final TextEditingController _titleController;
  late TimeOfDay _time;
  late String _type;
  late Set<int> _days;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _time = _parseTime(initial?.time) ?? TimeOfDay.now();
    _type = (initial?.type ?? 'journal').trim().isEmpty
        ? 'journal'
        : (initial?.type ?? 'journal');
    _days = {
      ...(initial?.daysOfWeek ?? const [0, 1, 2, 3, 4, 5, 6]),
    };
    _enabled = initial?.enabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(hhmm.trim());
    if (m == null) return null;
    final hh = int.tryParse(m.group(1)!) ?? 0;
    final mm = int.tryParse(m.group(2)!) ?? 0;
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
    return TimeOfDay(hour: hh, minute: mm);
  }

  String _toHHmm(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showMySnackBar(
        context: context,
        message: 'Title is required',
        color: Colors.red,
      );
      return;
    }

    final daysSorted = _days.toList()..sort();
    final payloadTime = _toHHmm(_time);

    final vm = ref.read(reminderViewModelProvider.notifier);
    final isEdit = widget.initial != null;

    final ok = isEdit
        ? await vm.updateReminder(
            id: widget.initial!.id,
            title: title,
            time: payloadTime,
            type: _type,
            daysOfWeek: daysSorted,
            enabled: _enabled,
          )
        : await vm.createReminder(
            title: title,
            time: payloadTime,
            type: _type,
            daysOfWeek: daysSorted,
            enabled: _enabled,
          );

    if (!ok) return;
    if (!mounted) return;
    Navigator.of(context).pop();
    showMySnackBar(
      context: context,
      message: isEdit ? 'Reminder updated' : 'Reminder created',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.initial != null;
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBCC7BE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    isEdit ? 'Edit reminder' : 'Create reminder',
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 18,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF2D5A44)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Set up a recurring prompt for journaling, mood, or exercise.',
                style: TextStyle(
                  fontFamily: 'Inter Regular',
                  fontSize: 12,
                  color: Color(0xFF5D6A62),
                ),
              ),
              const SizedBox(height: 14),
              const _SheetLabel(text: 'Title'),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'e.g. Evening reflection',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD8E5DD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD8E5DD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D5A44),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel(text: 'Time'),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD8E5DD)),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2A22),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatTimeOfDay(_time),
                            style: const TextStyle(fontFamily: 'Inter Medium'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel(text: 'Type'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_type),
                          initialValue: _type,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD8E5DD),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD8E5DD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2D5A44),
                                width: 1.2,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'journal',
                              child: Text('Journal'),
                            ),
                            DropdownMenuItem(
                              value: 'mood',
                              child: Text('Mood'),
                            ),
                            DropdownMenuItem(
                              value: 'exercise',
                              child: Text('Exercise'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _type = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SheetLabel(text: 'Repeat on'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final selected = _days.contains(index);
                  return FilterChip(
                    label: Text(dayLabels[index]),
                    selected: selected,
                    selectedColor: const Color(0xFFEAF1ED),
                    checkmarkColor: const Color(0xFF2D5A44),
                    labelStyle: TextStyle(
                      fontFamily: selected ? 'Inter Bold' : 'Inter Medium',
                      color: const Color(0xFF1F2A22),
                    ),
                    side: const BorderSide(color: Color(0xFFD8E5DD)),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _days.add(index);
                        } else {
                          _days.remove(index);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8E5DD)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text(
                    'Reminder is enabled',
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 14,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  activeColor: const Color(0xFF2D5A44),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD8E5DD)),
                        foregroundColor: const Color(0xFF1F2A22),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5A44),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(isEdit ? Icons.check : Icons.add),
                      label: Text(isEdit ? 'Save' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter Bold',
        fontSize: 12,
        color: Color(0xFF1F2A22),
      ),
    );
  }
}
