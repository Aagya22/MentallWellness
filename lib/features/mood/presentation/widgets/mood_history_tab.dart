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
    required this.onDelete,
  });

  final MoodState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(MoodEntity entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final entries = state.moods;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: entries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: const [_EmptyRecentMoodCard()],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: entries.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _HistorySummaryCard(entries: entries);
                }
                final entry = entries[index - 1];
                return _MoodEntryTile(
                  entry: entry,
                  onDelete: () => onDelete(entry),
                );
              },
            ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({required this.entries});

  final List<MoodEntity> entries;

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    final avg =
        entries.map((e) => e.mood).fold<int>(0, (sum, value) => sum + value) /
        count;
    final latest = entries.first;
    final latestEmoji = moodEmojiFor(
      moodType: latest.moodType,
      score: latest.mood,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5A44), Color(0xFF4E7A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(latestEmoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mood history',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count entries • ${avg.toStringAsFixed(1)}/10 average',
                  style: TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
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

class _MoodEntryTile extends StatelessWidget {
  const _MoodEntryTile({required this.entry, required this.onDelete});

  final MoodEntity entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, MMM d • h:mm a').format(entry.date);
    final info = moodVisualFor(entry.mood);
    final emoji = moodEmojiFor(moodType: entry.moodType, score: entry.mood);
    final moodType = (entry.moodType ?? '').trim();
    final note = (entry.note ?? '').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: info.background,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateText,
                        style: const TextStyle(
                          fontFamily: 'Inter Medium',
                          fontSize: 12,
                          color: Color(0xFF5A6B60),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${entry.mood}/10',
                        style: const TextStyle(
                          fontFamily: 'Inter Bold',
                          fontSize: 11,
                          color: Color(0xFF2D5A44),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Color(0xFF5A6B60),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (moodType.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    moodType,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 14,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: const TextStyle(
                      fontFamily: 'Inter Regular',
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF5A6B60),
                    ),
                    maxLines: 3,
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
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.sentiment_satisfied_alt_outlined,
            size: 34,
            color: Color(0xFF2D5A44),
          ),
          SizedBox(height: 10),
          Text(
            'No mood entries yet',
            style: TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 15,
              color: Color(0xFF1F2A22),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Log your first mood to start building your history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 12,
              color: Color(0xFF5D6A62),
            ),
          ),
        ],
      ),
    );
  }
}
