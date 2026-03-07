import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';

class MoodOverviewTab extends StatelessWidget {
  const MoodOverviewTab({
    super.key,
    required this.overview,
    required this.onRefresh,
  });

  final MoodOverviewEntity? overview;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final data = overview;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          if (data == null)
            const _OverviewEmptyState()
          else ...[
            _OverviewHeroCard(overview: data),
            const SizedBox(height: 14),
            const MoodSectionTitle(
              icon: Icons.grid_view_rounded,
              title: 'Key stats',
            ),
            const SizedBox(height: 10),
            _OverviewMetricGrid(overview: data),
            const SizedBox(height: 14),
            const MoodSectionTitle(
              icon: Icons.show_chart_rounded,
              title: 'Weekly mood map',
            ),
            const SizedBox(height: 10),
            _OverviewWeekStrip(overview: data),
            const SizedBox(height: 14),
            _OverviewInsightCard(overview: data),
          ],
        ],
      ),
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  const _OverviewHeroCard({required this.overview});

  final MoodOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final avgLabel = overview.avgThisWeek == null
        ? 'No average yet'
        : '${overview.avgThisWeek!.label} • ${overview.avgThisWeek!.score.toStringAsFixed(1)}/10';

    final loggedCount = overview.days.where((d) => d.entry != null).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood pulse this week',
            style: TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            avgLabel,
            style: TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: '${overview.streak} day streak'),
              _HeroPill(label: '$loggedCount entries this week'),
              _HeroPill(
                label: overview.mostFrequent == null
                    ? 'No frequent mood yet'
                    : 'Most frequent: ${overview.mostFrequent!.key}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter Medium',
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _OverviewMetricGrid extends StatelessWidget {
  const _OverviewMetricGrid({required this.overview});

  final MoodOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final loggedCount = overview.days.where((d) => d.entry != null).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MoodMetricCard(
                title: 'Average',
                value: overview.avgThisWeek == null
                    ? '—'
                    : '${overview.avgThisWeek!.label}\n${overview.avgThisWeek!.score.toStringAsFixed(1)}/10',
                icon: Icons.insights_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MoodMetricCard(
                title: 'Streak',
                value: '${overview.streak}\ndays',
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MoodMetricCard(
                title: 'Most frequent',
                value: overview.mostFrequent == null
                    ? '—'
                    : '${overview.mostFrequent!.key}\n${overview.mostFrequent!.count} time(s)',
                icon: Icons.auto_awesome_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MoodMetricCard(
                title: 'Logged',
                value: '$loggedCount\nthis week',
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewWeekStrip extends StatelessWidget {
  const _OverviewWeekStrip({required this.overview});

  final MoodOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Row(
        children: List.generate(overview.days.length, (index) {
          final item = overview.days[index];
          final score = item.entry?.mood;
          final emoji = moodEmojiFor(
            moodType: item.entry?.moodType,
            score: score,
          );
          final label = DateFormat('E').format(item.date);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == overview.days.length - 1 ? 0 : 6,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: score == null
                      ? const Color(0xFFF4F1EA)
                      : moodVisualFor(score).background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      score == null ? '·' : emoji,
                      style: const TextStyle(fontSize: 19),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter Medium',
                        fontSize: 11,
                        color: Color(0xFF1F2A22),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      score == null ? '—' : '$score',
                      style: const TextStyle(
                        fontFamily: 'Inter Bold',
                        fontSize: 11,
                        color: Color(0xFF2D5A44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OverviewInsightCard extends StatelessWidget {
  const _OverviewInsightCard({required this.overview});

  final MoodOverviewEntity overview;

  @override
  Widget build(BuildContext context) {
    final avg = overview.avgThisWeek?.score;
    final insight = avg == null
        ? 'Log at least one mood each day to unlock trends.'
        : avg >= 7
        ? 'Your average mood trend is positive this week. Keep your routine going.'
        : avg >= 5
        ? 'Your mood is steady overall. Small consistency wins can raise it further.'
        : 'This week looks emotionally heavy. Try one grounding or breathing session today.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF2D5A44),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                fontFamily: 'Inter Regular',
                fontSize: 12,
                color: Color(0xFF5A6B60),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewEmptyState extends StatelessWidget {
  const _OverviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.insights_outlined, size: 32, color: Color(0xFF2D5A44)),
          SizedBox(height: 10),
          Text(
            'No overview yet',
            style: TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 15,
              color: Color(0xFF1F2A22),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Log your mood to start seeing weekly patterns and insights.',
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
