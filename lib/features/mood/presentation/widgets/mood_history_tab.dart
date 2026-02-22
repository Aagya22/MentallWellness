import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/presentation/state/mood_state.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';

class MoodHistoryTab extends StatelessWidget {
  const MoodHistoryTab({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  final MoodState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: state.moods.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: const [
                _EmptyRecentMoodCard(),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: state.moods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _MoodEntryTile(entry: state.moods[index]);
              },
            ),
    );
  }
}

class _MoodEntryTile extends StatelessWidget {
  const _MoodEntryTile({required this.entry});

  final MoodEntity entry;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, MMM d').format(entry.date);
    final info = moodVisualFor(entry.mood);
    final emoji = moodEmojiFor(moodType: entry.moodType, score: entry.mood);
    final subtitle = [
      if (entry.moodType != null && entry.moodType!.trim().isNotEmpty) entry.moodType!.trim(),
      if (entry.note != null && entry.note!.trim().isNotEmpty) entry.note!.trim(),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: info.background,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateText • ${entry.mood}/10',
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 13,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF7B8A7E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentMoodCard extends StatelessWidget {
  const _EmptyRecentMoodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1ED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.sentiment_satisfied_alt_outlined,
              color: Color(0xFF2D5A44),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No mood entries yet',
              style: TextStyle(
                fontFamily: 'Inter Medium',
                fontSize: 13,
                color: Color(0xFF1F2A22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
