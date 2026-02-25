import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/core/services/notifications/local_notification_service_provider.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_notifications_state.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_notifications_viewmodel.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_state.dart';
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
      ref.read(reminderViewModelProvider.notifier).fetchReminders();
      ref.read(reminderNotificationsViewModelProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminderState = ref.watch(reminderViewModelProvider);
    final notificationState = ref.watch(reminderNotificationsViewModelProvider);
    final showSaving = reminderState.status == ReminderStatus.saving;
    final showNotifSaving = notificationState.status == ReminderNotificationsStatus.saving;

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

              final savingAny = showSaving || showNotifSaving;

              return Scaffold(
                backgroundColor: const Color(0xFFF4F1EA),
                appBar: AppBar(
                  backgroundColor: const Color(0xFFF4F1EA),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  title: const Text(
                    'Reminders',
                    style: TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 20,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  bottom: const TabBar(
                    labelColor: Color(0xFF1F2A22),
                    indicatorColor: Color(0xFF2D5A44),
                    tabs: [
                      Tab(text: 'Reminders'),
                      Tab(text: 'Notifications'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: savingAny
                          ? null
                          : () {
                              if (tabIndex == 0) {
                                ref.read(reminderViewModelProvider.notifier).fetchReminders();
                              } else {
                                ref.read(reminderNotificationsViewModelProvider.notifier).fetchHistory();
                              }
                            },
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D5A44)),
                      tooltip: 'Refresh',
                    ),
                    if (tabIndex == 1)
                      IconButton(
                        onPressed: savingAny
                            ? null
                            : () async {
                                final ok = await ref
                                    .read(reminderNotificationsViewModelProvider.notifier)
                                    .markAllRead();
                                if (ok && context.mounted) {
                                  showMySnackBar(
                                    context: context,
                                    message: 'All notifications marked as read',
                                  );
                                } else if (context.mounted) {
                                  showMySnackBar(
                                    context: context,
                                    message: 'Failed to mark all read',
                                    color: Colors.red,
                                  );
                                }
                              },
                        icon: const Icon(Icons.done_all_rounded, color: Color(0xFF2D5A44)),
                        tooltip: 'Mark all read',
                      ),
                    if (tabIndex == 1)
                      IconButton(
                        onPressed: savingAny
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Clear notification history?'),
                                    content:
                                        const Text('This will remove all reminder notifications.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true || !context.mounted) return;
                                final ok = await ref
                                    .read(reminderNotificationsViewModelProvider.notifier)
                                    .clearAll();
                                if (ok && context.mounted) {
                                  showMySnackBar(
                                    context: context,
                                    message: 'Notification history cleared',
                                  );
                                } else if (context.mounted) {
                                  showMySnackBar(
                                    context: context,
                                    message: 'Failed to clear notification history',
                                    color: Colors.red,
                                  );
                                }
                              },
                        icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF2D5A44)),
                        tooltip: 'Clear history',
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
                floatingActionButton: tabIndex == 0
                    ? FloatingActionButton(
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
                        shape: const CircleBorder(),
                        child: const Icon(Icons.add),
                      )
                    : null,
                body: Column(
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
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.state});

  final ReminderNotificationsState state;

  String _typeLabel(String type) {
    final t = type.trim().isEmpty ? 'journal' : type.trim();
    return t[0].toUpperCase() + t.substring(1);
  }

  String _whenLabel(DateTime dt) {
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.status == ReminderNotificationsStatus.loading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5A44)),
      );
    }

    if (state.notifications.isEmpty) {
      return const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(
            fontFamily: 'Inter Medium',
            color: Color(0xFF1F2A22),
          ),
        ),
      );
    }

    final saving = state.status == ReminderNotificationsStatus.saving;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: state.notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final n = state.notifications[index];
        return InkWell(
          onTap: saving
              ? null
              : () {
                  if (!n.isRead) {
                    ref.read(reminderNotificationsViewModelProvider.notifier).markRead(id: n.id);
                  }
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D5A44),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (!n.isRead) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: n.isRead ? 'Inter Medium' : 'Inter Bold',
                                fontSize: 14,
                                color: const Color(0xFF1F2A22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_whenLabel(n.scheduledFor)} • ${_typeLabel(n.type)}',
                        style: const TextStyle(
                          fontFamily: 'Inter Regular',
                          fontSize: 12,
                          color: Color(0xFF5D6A62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    if (state.reminders.isEmpty) {
      return const Center(
        child: Text(
          'No reminders yet',
          style: TextStyle(
            fontFamily: 'Inter Medium',
            color: Color(0xFF1F2A22),
          ),
        ),
      );
    }

    final saving = state.status == ReminderStatus.saving;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: state.reminders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = state.reminders[index];
        return _ReminderCard(
          reminder: r,
          disabled: saving,
          onTap: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _UpsertReminderSheet(initial: r),
            );
          },
          onToggleEnabled: saving
              ? null
              : (value) async {
                  final ok = await ref
                      .read(reminderViewModelProvider.notifier)
                      .updateReminder(id: r.id, enabled: value);
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
                      content: Text('"${r.title}" will be removed.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true || !context.mounted) return;

                  final ok = await ref
                      .read(reminderViewModelProvider.notifier)
                      .deleteReminder(id: r.id);
                  if (ok && context.mounted) {
                    showMySnackBar(context: context, message: 'Reminder deleted');
                  }
                },
        );
      },
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

  String _daysLabel(List<int> days) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final unique = {...days.where((d) => d >= 0 && d <= 6)}.toList()..sort();
    if (unique.length == 7) return 'Everyday';
    if (unique.isEmpty) return 'No days';
    return unique.map((d) => names[d]).join(', ');
  }

  String _typeLabel(String type) {
    final t = type.trim().isEmpty ? 'journal' : type.trim();
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 14,
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
                  const SizedBox(height: 4),
                  Text(
                    _daysLabel(reminder.daysOfWeek),
                    style: const TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      color: Color(0xFF5D6A62),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: reminder.enabled,
              onChanged: disabled ? null : onToggleEnabled,
              activeThumbColor: const Color(0xFF2D5A44),
            ),
            IconButton(
              onPressed: disabled ? null : onDelete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFF8B2E2E)),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _UpsertReminderSheet extends ConsumerStatefulWidget {
  const _UpsertReminderSheet({this.initial});

  final ReminderEntity? initial;

  @override
  ConsumerState<_UpsertReminderSheet> createState() => _UpsertReminderSheetState();
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
    _type = (initial?.type ?? 'journal').trim().isEmpty ? 'journal' : (initial?.type ?? 'journal');
    _days = {...(initial?.daysOfWeek ?? const [0, 1, 2, 3, 4, 5, 6])};
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked == null) return;
    setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showMySnackBar(context: context, message: 'Title is required', color: Colors.red);
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

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? 'Edit reminder' : 'New reminder',
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 16,
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
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        MaterialLocalizations.of(context).formatTimeOfDay(_time),
                        style: const TextStyle(fontFamily: 'Inter Medium'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_type),
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'journal', child: Text('Journal')),
                        DropdownMenuItem(value: 'mood', child: Text('Mood')),
                        DropdownMenuItem(value: 'exercise', child: Text('Exercise')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _type = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Days',
                style: TextStyle(
                  fontFamily: 'Inter Bold',
                  fontSize: 13,
                  color: Color(0xFF1F2A22),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  final selected = _days.contains(index);
                  return FilterChip(
                    label: Text(labels[index]),
                    selected: selected,
                    selectedColor: const Color(0xFFEAF1ED),
                    checkmarkColor: const Color(0xFF2D5A44),
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text(
                  'Enabled',
                  style: TextStyle(fontFamily: 'Inter Medium', color: Color(0xFF1F2A22)),
                ),
                activeThumbColor: const Color(0xFF2D5A44),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A44),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
