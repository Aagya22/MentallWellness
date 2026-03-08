import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_overview_tab.dart';

void main() {
  MoodOverviewEntity buildOverview({required double avgScore}) {
    final monday = DateTime(2026, 3, 2);
    return MoodOverviewEntity(
      weekStart: monday,
      days: List.generate(7, (index) {
        return MoodOverviewDayEntity(
          date: monday.add(Duration(days: index)),
          entry: MoodEntity(
            id: 'm$index',
            mood: avgScore.round(),
            moodType: 'Calm',
            date: monday.add(Duration(days: index, hours: 8)),
          ),
        );
      }),
      avgThisWeek: MoodAverageEntity(score: avgScore, label: 'Good'),
      streak: 5,
      mostFrequent: const MoodMostFrequentEntity(key: 'Calm', count: 3),
    );
  }

  Future<void> pumpTab(WidgetTester tester, MoodOverviewEntity? overview) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodOverviewTab(
            overview: overview,
            onRefresh: () async {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows empty state when overview is null', (tester) async {
    await pumpTab(tester, null);

    expect(find.text('No overview yet'), findsOneWidget);
    expect(find.text('Log your mood to start seeing weekly patterns and insights.'), findsOneWidget);
  });

  testWidgets('shows key stats section when overview data exists', (tester) async {
    await pumpTab(tester, buildOverview(avgScore: 7.2));

    expect(find.text('Key stats'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Most frequent'), findsOneWidget);
    expect(find.text('Logged'), findsOneWidget);
  });

  testWidgets('shows heavy-week insight when average is low', (tester) async {
    await pumpTab(tester, buildOverview(avgScore: 4.2));

    expect(find.textContaining('emotionally heavy'), findsOneWidget);
  });

  testWidgets('shows positive insight when average is high', (tester) async {
    await pumpTab(tester, buildOverview(avgScore: 8.1));

    expect(find.textContaining('positive this week'), findsOneWidget);
  });
}
