import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_empty_section_card.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_notification_entity.dart';

class HomeRemindersSection extends StatelessWidget {
  const HomeRemindersSection({
    super.key,
    required this.isLoading,
    required this.reminders,
    required this.notifications,
    required this.onTapReminders,
  });

  final bool isLoading;
  final List<ReminderEntity> reminders;
  final List<ReminderNotificationEntity> notifications;
  final VoidCallback onTapReminders;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Loading…',
          style: TextStyle(
            fontFamily: 'Inter Medium',
            fontSize: 13,
            color: Color(0xFF7B8A7E),
          ),
        ),
      );
    }

    if (reminders.isEmpty) {
      return HomeEmptySectionCard(
        icon: Icons.notifications_active_outlined,
        message: 'No reminders yet',
        ctaText: 'Create reminder',
        onTap: onTapReminders,
      );
    }

    final enabledCount = reminders.where((r) => r.enabled).length;
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final latest = notifications.isNotEmpty ? notifications.first : null;

    return InkWell(
      onTap: onTapReminders,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1ED),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF2D5A44),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$enabledCount active reminder${enabledCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 13,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unreadCount > 0
                        ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}'
                        : (latest != null
                              ? 'Last: ${latest.title} • ${_formatTime(latest.scheduledFor)}'
                              : 'All caught up'),
                    style: const TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 11,
                      color: Color(0xFF8B978E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF7B8A7E),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }
}
