import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';

class HomeEventsSection extends StatelessWidget {
  const HomeEventsSection({
    super.key,
    required this.isLoading,
    required this.schedules,
  });

  final bool isLoading;
  final List<ScheduleEntity> schedules;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
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

    final now = DateTime.now();
    final upcoming = schedules
        .map((s) => _ScheduleWithDateTime(s, _parseScheduleDateTime(s)))
        .where((x) => x.when != null && !x.when!.isBefore(now))
        .toList();

    upcoming.sort((a, b) => a.when!.compareTo(b.when!));

    final top = upcoming.take(3).toList();

    if (top.isEmpty) {
      return const _EmptyEventsCard();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (final x in top)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventRow(schedule: x.schedule, when: x.when!),
            ),
        ],
      ),
    );
  }

  DateTime? _parseScheduleDateTime(ScheduleEntity s) {
    try {
      final date = DateTime.parse(s.date); // local midnight
      final parts = s.time.split(':');
      final hh = int.parse(parts[0]);
      final mm = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hh, mm);
    } catch (_) {
      return null;
    }
  }
}

class _ScheduleWithDateTime {
  final ScheduleEntity schedule;
  final DateTime? when;

  _ScheduleWithDateTime(this.schedule, this.when);
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.schedule, required this.when});

  final ScheduleEntity schedule;
  final DateTime when;

  @override
  Widget build(BuildContext context) {
    final whenText = DateFormat('EEE, MMM d • h:mm a').format(when);
    return Row(
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
            Icons.calendar_month_outlined,
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
                schedule.title,
                style: const TextStyle(
                  fontFamily: 'Inter Medium',
                  fontSize: 13,
                  color: Color(0xFF1F2A22),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                whenText,
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
      ],
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
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
              Icons.calendar_month_outlined,
              color: Color(0xFF2D5A44),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming events',
                  style: TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 13,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add events to see them here',
                  style: TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 11,
                    color: Color(0xFF8B978E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
