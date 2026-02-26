import 'package:flutter/material.dart';

class HomeQuickActionsSection extends StatelessWidget {
  const HomeQuickActionsSection({
    super.key,
    required this.onTapJournal,
    required this.onTapExercises,
  });

  final VoidCallback onTapJournal;
  final VoidCallback onTapExercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay Bold',
            fontSize: 18,
            color: Color(0xFF1F2A22),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                tag: 'JOURNAL',
                title: 'Journal',
                actionText: 'Write today',
                accentColor: const Color(0xFFF1E3DD),
                trailingAsset: 'assets/images/journal.jpg',
                onTap: onTapJournal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                tag: 'EXERCISES',
                title: 'Exercises',
                actionText: 'Log workout',
                accentColor: const Color(0xFFE4F0EA),
                trailingAsset: 'assets/images/meditate.jpg',
                onTap: onTapExercises,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.tag,
    required this.title,
    required this.actionText,
    required this.accentColor,
    required this.trailingAsset,
    required this.onTap,
  });

  final String tag;
  final String title;
  final String actionText;
  final Color accentColor;
  final String trailingAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 150,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  trailingAsset,
                  height: 58,
                  width: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: 'Inter Bold',
                      fontSize: 9,
                      color: Color(0xFF2D5A44),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay Bold',
                    fontSize: 20,
                    height: 1.1,
                    color: Color(0xFF1F2A22),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      actionText,
                      style: const TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 12,
                        color: Color(0xFF2D5A44),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF2D5A44),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
