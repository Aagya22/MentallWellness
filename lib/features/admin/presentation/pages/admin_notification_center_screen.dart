import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';
import 'package:mentalwellness/features/admin/data/models/admin_notification_model.dart';
import 'package:mentalwellness/features/admin/presentation/state/admin_notifications_state.dart';
import 'package:mentalwellness/features/admin/presentation/view_model/admin_notifications_viewmodel.dart';

const _adminPrimary = Color(0xFF4F46E5);
const _adminSecondary = Color(0xFF7C3AED);
const _adminBg = Color(0xFFF1F5F9);

class AdminNotificationCenterScreen extends ConsumerStatefulWidget {
  const AdminNotificationCenterScreen({super.key});

  @override
  ConsumerState<AdminNotificationCenterScreen> createState() =>
      _AdminNotificationCenterScreenState();
}

class _AdminNotificationCenterScreenState
    extends ConsumerState<AdminNotificationCenterScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(adminNotificationsViewModelProvider.notifier)
          .fetchNotifications(limit: 80);
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(adminNotificationsViewModelProvider.notifier)
        .fetchNotifications(limit: 80);
  }

  Future<void> _markAllRead() async {
    final ok = await ref
        .read(adminNotificationsViewModelProvider.notifier)
        .markAllRead();
    if (!mounted) return;

    showMySnackBar(
      context: context,
      message: ok
          ? 'All notifications marked as read'
          : 'Failed to mark all as read',
      color: ok ? null : Colors.red,
    );
  }

  Future<void> _clearAll() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    color: const Color(0xFFC7CEDB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const Text(
                  'Clear all notifications?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This removes all admin notifications permanently.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
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
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Clear all'),
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

    final ok = await ref
        .read(adminNotificationsViewModelProvider.notifier)
        .clearAll();
    if (!mounted) return;

    showMySnackBar(
      context: context,
      message: ok ? 'Notifications cleared' : 'Failed to clear notifications',
      color: ok ? null : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotificationsViewModelProvider);

    ref.listen(adminNotificationsViewModelProvider, (prev, next) {
      final prevMsg = prev?.errorMessage;
      final nextMsg = next.errorMessage;
      if (nextMsg != null && nextMsg.isNotEmpty && nextMsg != prevMsg) {
        showMySnackBar(context: context, message: nextMsg, color: Colors.red);
      }
    });

    final all = state.notifications;
    final unreadCount = state.unreadCount;
    final visible = _showUnreadOnly
        ? all.where((n) => !n.isRead).toList()
        : all;

    final isLoadingEmpty =
        (state.status == AdminNotificationsStatus.loading ||
            state.status == AdminNotificationsStatus.initial) &&
        all.isEmpty;
    final isBusy =
        state.status == AdminNotificationsStatus.loading ||
        state.status == AdminNotificationsStatus.saving;

    return Scaffold(
      backgroundColor: _adminBg,
      appBar: AppBar(
        backgroundColor: _adminBg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: isBusy || unreadCount == 0 ? null : _markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: _adminPrimary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: isBusy || all.isEmpty ? null : _clearAll,
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFB91C1C),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _adminPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isBusy)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: _adminPrimary,
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _AdminSummaryCard(
                  totalCount: all.length,
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
                  child: CircularProgressIndicator(color: _adminPrimary),
                ),
              )
            else if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = visible[index];
                    return _NotificationCard(
                      notification: item,
                      onTap: () {
                        if (!item.isRead) {
                          ref
                              .read(
                                adminNotificationsViewModelProvider.notifier,
                              )
                              .markRead(id: item.id);
                        }
                      },
                      onMarkRead: item.isRead
                          ? null
                          : () {
                              ref
                                  .read(
                                    adminNotificationsViewModelProvider
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

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({
    required this.totalCount,
    required this.unreadCount,
  });

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
          colors: [_adminPrimary, _adminSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
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
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFE5E7EB),
            fontWeight: FontWeight.w500,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _adminPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _adminPrimary : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    this.onMarkRead,
  });

  final AdminNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final createdAt = notification.createdAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? const Color(0xFFE5E7EB) : const Color(0xFFC7D2FE),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isRead
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      size: 18,
                      color: isRead
                          ? const Color(0xFF64748B)
                          : const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notification.message,
                      style: TextStyle(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notification.userFullName,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                notification.userEmail,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdAt == null
                        ? '--'
                        : DateFormat('MMM d, y • h:mm a').format(createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.5,
                    ),
                  ),
                  const Spacer(),
                  if (!isRead && onMarkRead != null)
                    TextButton(
                      onPressed: onMarkRead,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: _adminPrimary,
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Mark read'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 34,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No notifications yet',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'New user registration alerts will appear here for admins.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
