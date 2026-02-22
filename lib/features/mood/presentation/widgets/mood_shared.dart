import 'package:emojis/emojis.dart';
import 'package:flutter/material.dart';

class MoodOption {
  final String label;
  final int score;
  final String emoji;

  const MoodOption({
    required this.label,
    required this.score,
    required this.emoji,
  });
}

const List<MoodOption> kMoodOptions = [
  MoodOption(label: 'Joyful', score: 9, emoji: Emojis.faceWithTearsOfJoy),
  MoodOption(label: 'Happy', score: 8, emoji: Emojis.smilingFaceWithSmilingEyes),
  MoodOption(label: 'Hopeful', score: 8, emoji: Emojis.slightlySmilingFace),
  MoodOption(label: 'Content', score: 7, emoji: Emojis.smilingFace),
  MoodOption(label: 'Calm', score: 7, emoji: Emojis.relievedFace),
  MoodOption(label: 'Neutral', score: 6, emoji: Emojis.neutralFace),
  MoodOption(label: 'Tired', score: 5, emoji: Emojis.sleepyFace),
  MoodOption(label: 'Anxious', score: 4, emoji: Emojis.anxiousFaceWithSweat),
  MoodOption(label: 'Sad', score: 3, emoji: Emojis.pensiveFace),
  MoodOption(label: 'Stressed', score: 3, emoji: Emojis.anguishedFace),
  MoodOption(label: 'Angry', score: 2, emoji: Emojis.angryFace),
];

String moodEmojiFor({required String? moodType, required int? score}) {
  final normalized = (moodType ?? '').trim().toLowerCase();
  for (final opt in kMoodOptions) {
    if (opt.label.toLowerCase() == normalized) return opt.emoji;
  }

  final s = score ?? 0;
  if (s <= 2) return Emojis.disappointedFace;
  if (s <= 4) return Emojis.worriedFace;
  if (s <= 6) return Emojis.neutralFace;
  if (s <= 8) return Emojis.slightlySmilingFace;
  return Emojis.grinningFaceWithBigEyes;
}

class MoodSectionTitle extends StatelessWidget {
  const MoodSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3C4D42)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
      ],
    );
  }
}

class MoodMetricCard extends StatelessWidget {
  const MoodMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2D5A44)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter Medium',
                    fontSize: 12,
                    color: Color(0xFF7B8A7E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 14,
                    height: 1.25,
                    color: Color(0xFF1F2A22),
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

class MoodVisual {
  final IconData icon;
  final Color background;

  const MoodVisual({required this.icon, required this.background});
}

MoodVisual moodVisualFor(int? mood) {
  if (mood == null) {
    return const MoodVisual(icon: Icons.remove, background: Color(0xFFF4F1EA));
  }
  if (mood <= 2) {
    return const MoodVisual(
      icon: Icons.sentiment_very_dissatisfied,
      background: Color(0xFFF1E3DD),
    );
  }
  if (mood <= 4) {
    return const MoodVisual(
      icon: Icons.sentiment_dissatisfied,
      background: Color(0xFFF1E3DD),
    );
  }
  if (mood <= 6) {
    return const MoodVisual(
      icon: Icons.sentiment_neutral,
      background: Color(0xFFF4F1EA),
    );
  }
  if (mood <= 8) {
    return const MoodVisual(
      icon: Icons.sentiment_satisfied,
      background: Color(0xFFE4F0EA),
    );
  }
  return const MoodVisual(
    icon: Icons.sentiment_very_satisfied,
    background: Color(0xFFE4F0EA),
  );
}
