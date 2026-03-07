import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';
import 'package:mentalwellness/features/reminder/presentation/state/reminder_notifications_state.dart';
import 'package:mentalwellness/features/reminder/presentation/view_model/reminder_notifications_viewmodel.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reminderNotificationsViewModelProvider.notifier).fetchHistory();
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(reminderNotificationsViewModelProvider.notifier)
        .fetchHistory(limit: 50);
  }

  Future<void> _markAllRead() async {
    final vm = ref.read(reminderNotificationsViewModelProvider.notifier);
    final ok = await vm.markAllRead();
    if (!mounted) return;

    showMySnackBar(
      context: context,
      message: ok
          ? 'All notifications marked as read'
          : 'Failed to mark all as read',
      color: ok ? null : Colors.red,
    );
  }

  Future<void> _clearHistory() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F1EA),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8C1BA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const Text(
                  'Delete all notifications?',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 17,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action clears your full notification history and cannot be undone.',
                  style: TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 13,
                    color: Color(0xFF5D6A62),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2A22),
                          side: const BorderSide(color: Color(0xFFCBD5CE)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B2E2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    final vm = ref.read(reminderNotificationsViewModelProvider.notifier);
    final ok = await vm.clearAll();
    if (!mounted) return;

    showMySnackBar(
      context: context,
      message: ok
          ? 'Notification history deleted'
          : 'Failed to delete notification history',
      color: ok ? null : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderNotificationsViewModelProvider);

    ref.listen(reminderNotificationsViewModelProvider, (prev, next) {
      final prevMsg = prev?.errorMessage;
      final nextMsg = next.errorMessage;
      if (nextMsg != null && nextMsg.isNotEmpty && nextMsg != prevMsg) {
        showMySnackBar(context: context, message: nextMsg, color: Colors.red);
      }
    });

    final notifications = state.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final visibleNotifications = _showUnreadOnly
        ? notifications.where((n) => !n.isRead).toList()
        : notifications;

    final isLoadingEmpty =
        (state.status == ReminderNotificationsStatus.loading ||
            state.status == ReminderNotificationsStatus.initial) &&
        notifications.isEmpty;
    final isBusy =
        state.status == ReminderNotificationsStatus.loading ||
        state.status == ReminderNotificationsStatus.saving;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 20,
            color: Color(0xFF1F2A22),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: isBusy || unreadCount == 0 ? null : _markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2D5A44),
              textStyle: const TextStyle(fontFamily: 'Inter Medium'),
            ),
          ),
          IconButton(
            onPressed: isBusy || notifications.isEmpty ? null : _clearHistory,
            tooltip: 'Delete history',
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFF8B2E2E),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF2D5A44),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isBusy)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF2D5A44),
                  backgroundColor: Color(0xFFEAF1ED),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _SummaryCard(
                  totalCount: notifications.length,
                  unreadCount: unreadCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: !_showUnreadOnly,
                      onTap: () => setState(() => _showUnreadOnly = false),
                    ),
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: 'Unread',
                      selected: _showUnreadOnly,
                      onTap: () => setState(() => _showUnreadOnly = true),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoadingEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D5A44)),
                ),
              )
            else if (visibleNotifications.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyNotificationsState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.separated(
                  itemCount: visibleNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = visibleNotifications[index];
                    return _NotificationCard(
                      notification: item,
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
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalCount, required this.unreadCount});

  final int totalCount;
  final int unreadCount;

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
            color: Color(0x331C3C2C),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(label: 'Unread', value: unreadCount.toString()),
          ),
          Container(width: 1, height: 30, color: const Color(0x66FFFFFF)),
          Expanded(
            child: _SummaryItem(label: 'Total', value: totalCount.toString()),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter Bold',
            fontSize: 20,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: selected ? 'Inter Bold' : 'Inter Medium',
          color: selected ? Colors.white : const Color(0xFF1F2A22),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF2D5A44),
      backgroundColor: const Color(0xFFE7ECE8),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  });

  final ReminderNotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  String _typeLabel(String type) {
    final t = type.trim().isEmpty ? 'journal' : type.trim();
    return t[0].toUpperCase() + t.substring(1);
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final localTime = DateFormat('h:mm a').format(dt);

    if (target == today) return 'Today, $localTime';
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $localTime';
    }
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
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

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: unread ? const Color(0xFFFFFFFF) : const Color(0xFFF8FAF8),
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
                      '${_typeLabel(notification.type)} • ${_formatWhen(notification.deliveredAt)}',
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
                            borderRadius: BorderRadius.circular(30),
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
                            onPressed: onMarkRead,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Mark read'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2D5A44),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter Medium',
                                fontSize: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
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
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EDE8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: Color(0xFF2D5A44),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 16,
              color: Color(0xFF1F2A22),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'When reminders are delivered, they will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
