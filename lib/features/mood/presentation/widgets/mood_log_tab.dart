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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          _MoodLogHeroCard(
            selectedLabel: selectedLabel,
            selectedScore: selectedScore,
          ),
          const SizedBox(height: 14),
          const MoodSectionTitle(
            icon: Icons.mood_rounded,
            title: 'Pick your mood',
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose the emotion that feels closest right now.',
            style: TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 12,
              color: Color(0xFF5D6A62),
            ),
          ),
          const SizedBox(height: 10),
          MoodPickerGrid(selectedLabel: selectedLabel, onSelect: onSelect),
          const SizedBox(height: 16),
          const MoodSectionTitle(
            icon: Icons.edit_note_outlined,
            title: 'Note (optional)',
          ),
          const SizedBox(height: 10),
          MoodNoteCard(
            selectedLabel: selectedLabel,
            selectedScore: selectedScore,
            noteController: noteController,
            disabled: saving,
          ),
          const SizedBox(height: 16),
          const MoodSectionTitle(
            icon: Icons.calendar_month_rounded,
            title: 'This week',
          ),
          const SizedBox(height: 10),
          MoodWeeklyOverviewCard(overview: state.overview),
          const SizedBox(height: 16),
          MoodSaveButton(enabled: canSave, saving: saving, onPressed: onSave),
        ],
      ),
    );
  }
}

class _MoodLogHeroCard extends StatelessWidget {
  const _MoodLogHeroCard({
    required this.selectedLabel,
    required this.selectedScore,
  });

  final String? selectedLabel;
  final int? selectedScore;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedLabel != null && selectedScore != null;
    final emoji = moodEmojiFor(moodType: selectedLabel, score: selectedScore);

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              hasSelection ? emoji : '🙂',
              style: const TextStyle(fontSize: 25),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mood check-in',
                  style: TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSelection
                      ? '$selectedLabel • ${selectedScore.toString()}/10 selected'
                      : 'Select your current mood and save a quick note.',
                  style: TextStyle(
                    fontFamily: 'Inter Regular',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
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
    final moodVisual = moodVisualFor(score);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: moodVisual.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  (label == null || score == null) ? '·' : emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  score == null || label == null
                      ? 'No mood selected yet'
                      : '$label • $score/10',
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 14,
                    color: Color(0xFF1F2A22),
                  ),
                ),
              ),
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Selected',
                    style: TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 11,
                      color: Color(0xFF2D5A44),
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
            style: const TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 14,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: 'What made you feel this way?',
              border: OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: Color(0xFFF4F1EA),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5A44),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB8C5BD),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: Icon(saving ? Icons.sync : Icons.save_outlined),
            label: Text(
              saving ? 'Saving...' : 'Save mood',
              style: const TextStyle(fontFamily: 'Inter Bold'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            enabled
                ? 'Your entry will appear in History immediately.'
                : 'Pick a mood first to enable saving.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 11,
              color: Color(0xFF5D6A62),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodWeeklyOverviewCard extends StatelessWidget {
  const MoodWeeklyOverviewCard({super.key, required this.overview});

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
          border: Border.all(color: const Color(0xFFDCE7E1)),
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
    final loggedCount = data.days.where((day) => day.entry != null).length;
    final average = data.avgThisWeek?.score;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Week of $weekLabel',
                style: const TextStyle(
                  fontFamily: 'Inter Medium',
                  fontSize: 12,
                  color: Color(0xFF7B8A7E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$loggedCount days logged',
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 11,
                    color: Color(0xFF2D5A44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (average != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Average ${average.toStringAsFixed(1)}/10',
                style: const TextStyle(
                  fontFamily: 'Inter Bold',
                  fontSize: 13,
                  color: Color(0xFF1F2A22),
                ),
              ),
            ),
          Row(
            children: List.generate(data.days.length, (i) {
              final day = data.days[i];
              final dayName = DateFormat('E').format(day.date);
              final moodLabel = (day.entry?.moodType ?? '').trim();
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == data.days.length - 1 ? 0 : 6,
                  ),
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
              : Text(emoji, style: const TextStyle(fontSize: 20)),
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
