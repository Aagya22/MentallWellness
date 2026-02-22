import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const MoodSectionTitle(icon: Icons.insights, title: 'Overview'),
          const SizedBox(height: 10),
          if (data == null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No overview yet',
                style: TextStyle(
                  fontFamily: 'Inter Medium',
                  fontSize: 13,
                  color: Color(0xFF1F2A22),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: MoodMetricCard(
                    title: 'Average',
                    value: data.avgThisWeek == null
                        ? '—'
                        : '${data.avgThisWeek!.label}\n${data.avgThisWeek!.score.toStringAsFixed(1)}/10',
                    icon: Icons.insights,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MoodMetricCard(
                    title: 'Streak',
                    value: '${data.streak}\ndays',
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
                    value: data.mostFrequent == null
                        ? '—'
                        : '${data.mostFrequent!.key}\n${data.mostFrequent!.count} time(s)',
                    icon: Icons.auto_awesome_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MoodMetricCard(
                    title: 'Logged',
                    value: '${data.days.where((d) => d.entry != null).length}\nthis week',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
