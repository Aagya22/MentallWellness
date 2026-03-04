import 'package:flutter/material.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_empty_section_card.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';

class HomeWeeklyMoodSection extends StatelessWidget {
  const HomeWeeklyMoodSection({
    super.key,
    required this.overview,
    required this.isLoading,
    required this.onTapLogMood,
  });

  final MoodOverviewEntity? overview;
  final bool isLoading;
  final VoidCallback onTapLogMood;

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

    final days = overview?.days ?? const <MoodOverviewDayEntity>[];
    final hasAny = days.any((d) => d.entry != null);
    if (!hasAny) {
      return HomeEmptySectionCard(
        icon: Icons.sentiment_satisfied_alt_outlined,
        message: 'No mood entries yet',
        ctaText: 'Log mood',
        onTap: onTapLogMood,
      );
    }

    final avg = overview?.avgThisWeek;
    final streak = overview?.streak ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (avg != null)
                _Pill(text: '${avg.label} (${avg.score.toStringAsFixed(1)})'),
              if (avg != null) const SizedBox(width: 8),
              _Pill(text: 'Streak: $streak'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in days.take(7))
                Expanded(
                  child: _DayMoodCell(
                    date: d.date,
                    moodType: d.entry?.moodType,
                    score: d.entry?.mood,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter Bold',
          fontSize: 11,
          color: Color(0xFF2D5A44),
        ),
      ),
    );
  }
}

class _DayMoodCell extends StatelessWidget {
  const _DayMoodCell({
    required this.date,
    required this.moodType,
    required this.score,
  });

  final DateTime date;
  final String? moodType;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final label = _weekdayLetter(date.weekday);
    final emoji = moodEmojiFor(moodType: moodType, score: score);
    final hasEntry = score != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 11,
              color: Color(0xFF7B8A7E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: hasEntry
                  ? const Color(0xFFEAF1ED)
                  : const Color(0xFFF4F1EA),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              hasEntry ? emoji : '—',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLetter(int weekday) {
    // DateTime.weekday: Mon=1..Sun=7
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }
}
