import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/presentation/state/mood_state.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_picker_grid.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';

class MoodLogTab extends StatelessWidget {
  const MoodLogTab({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.selectedLabel,
    required this.selectedScore,
    required this.onSelect,
    required this.noteController,
    required this.onSave,
  });

  final MoodState state;
  final Future<void> Function() onRefresh;
  final String? selectedLabel;
  final int? selectedScore;
  final void Function(String label, int score) onSelect;
  final TextEditingController noteController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final saving = state.status == MoodStatus.saving;
    final canSave = !saving && selectedLabel != null && selectedScore != null;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay Bold',
              fontSize: 20,
              color: Color(0xFF1F2A22),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a mood to log',
            style: TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 13,
              color: Color(0xFF7B8A7E),
            ),
          ),
          const SizedBox(height: 12),
          MoodPickerGrid(
            selectedLabel: selectedLabel,
            onSelect: onSelect,
          ),
          const SizedBox(height: 18),
          const MoodSectionTitle(icon: Icons.edit_note_outlined, title: 'Note (optional)'),
          const SizedBox(height: 10),
          MoodNoteCard(
            selectedLabel: selectedLabel,
            selectedScore: selectedScore,
            noteController: noteController,
            disabled: saving,
          ),
          const SizedBox(height: 18),
          const MoodSectionTitle(icon: Icons.blur_circular, title: 'This week'),
          const SizedBox(height: 10),
          MoodWeeklyOverviewCard(overview: state.overview),
          const SizedBox(height: 18),
          MoodSaveButton(
            enabled: canSave,
            saving: saving,
            onPressed: onSave,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class MoodNoteCard extends StatelessWidget {
  const MoodNoteCard({
    super.key,
    required this.selectedLabel,
    required this.selectedScore,
    required this.noteController,
    required this.disabled,
  });

  final String? selectedLabel;
  final int? selectedScore;
  final TextEditingController noteController;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final label = selectedLabel;
    final score = selectedScore;
    final emoji = moodEmojiFor(moodType: label, score: score);
    final bg = moodVisualFor(score).background;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  (label == null || score == null) ? '·' : emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  score == null || label == null ? 'Select a mood to log' : '$label • $score/10',
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 14,
                    color: Color(0xFF1F2A22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            enabled: !disabled,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(fontFamily: 'Inter Regular', fontSize: 14, height: 1.4),
            decoration: const InputDecoration(
              hintText: 'What made you feel this way?',
              border: OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: Color(0xFFF4F1EA),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodSaveButton extends StatelessWidget {
  const MoodSaveButton({
    super.key,
    required this.enabled,
    required this.saving,
    required this.onPressed,
  });

  final bool enabled;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5A44),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          saving ? 'Saving...' : 'Save mood',
          style: const TextStyle(fontFamily: 'Inter Bold'),
        ),
      ),
    );
  }
}

class MoodWeeklyOverviewCard extends StatelessWidget {
  const MoodWeeklyOverviewCard({
    super.key,
    required this.overview,
  });

  final MoodOverviewEntity? overview;

  @override
  Widget build(BuildContext context) {
    final data = overview;
    if (data == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No mood overview yet',
          style: TextStyle(
            fontFamily: 'Inter Medium',
            fontSize: 13,
            color: Color(0xFF1F2A22),
          ),
        ),
      );
    }

    final weekLabel = DateFormat('MMM d').format(data.weekStart);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week of $weekLabel',
            style: const TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 12,
              color: Color(0xFF7B8A7E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(data.days.length, (i) {
              final day = data.days[i];
              final dayName = DateFormat('E').format(day.date);
              final moodLabel = (day.entry?.moodType ?? '').trim();
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == data.days.length - 1 ? 0 : 6),
                  child: _WeekDayMoodDot(
                    dayLabel: dayName,
                    moodLabel: moodLabel,
                    entry: day.entry,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeekDayMoodDot extends StatelessWidget {
  const _WeekDayMoodDot({
    required this.dayLabel,
    required this.moodLabel,
    required this.entry,
  });

  final String dayLabel;
  final String moodLabel;
  final MoodEntity? entry;

  @override
  Widget build(BuildContext context) {
    final emoji = moodEmojiFor(moodType: entry?.moodType, score: entry?.mood);
    final border = entry == null
        ? const Color(0xFFEAF1ED)
        : const Color(0xFF2D5A44).withValues(alpha: 0.25);

    return Column(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 2),
          ),
          alignment: Alignment.center,
          child: entry == null
              ? const Text(
                  '·',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 22,
                    color: Color(0xFF7B8A7E),
                  ),
                )
              : Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          dayLabel,
          style: const TextStyle(
            fontFamily: 'Inter Medium',
            fontSize: 12,
            color: Color(0xFF1F2A22),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          moodLabel.isEmpty ? '' : moodLabel,
          style: const TextStyle(
            fontFamily: 'Inter Regular',
            fontSize: 11,
            color: Color(0xFF7B8A7E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
