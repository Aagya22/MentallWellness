import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/presentation/state/mood_state.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_history_tab.dart';

void main() {
  MoodEntity buildMood({
    required String id,
    required int score,
    required DateTime date,
    String? moodType,
    String? note,
  }) {
    return MoodEntity(
      id: id,
      mood: score,
      moodType: moodType,
      note: note,
      date: date,
    );
  }

  Future<void> pumpTab(
    WidgetTester tester, {
    required MoodState state,
    required Future<void> Function(MoodEntity entry) onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodHistoryTab(
            state: state,
            onRefresh: () async {},
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }

  testWidgets('shows empty state card when no entries are present', (tester) async {
    await pumpTab(
      tester,
      state: const MoodState(status: MoodStatus.loaded, moods: []),
      onDelete: (_) async {},
    );

    expect(find.text('No mood entries yet'), findsOneWidget);
    expect(find.text('Log your first mood to start building your history.'), findsOneWidget);
  });

  testWidgets('shows summary card with entry count and average', (tester) async {
    final entries = [
      buildMood(id: 'm1', score: 8, moodType: 'Happy', date: DateTime(2026, 3, 8, 9)),
      buildMood(id: 'm2', score: 6, moodType: 'Neutral', date: DateTime(2026, 3, 7, 10)),
    ];

    await pumpTab(
      tester,
      state: MoodState(status: MoodStatus.loaded, moods: entries),
      onDelete: (_) async {},
    );

    expect(find.text('Mood history'), findsOneWidget);
    expect(find.text('2 entries • 7.0/10 average'), findsOneWidget);
  });

  testWidgets('shows mood entry details including mood type and note', (tester) async {
    final entries = [
      buildMood(
        id: 'm1',
        score: 5,
        moodType: 'Tired',
        note: 'Long day at work',
        date: DateTime(2026, 3, 8, 9),
      ),
    ];

    await pumpTab(
      tester,
      state: MoodState(status: MoodStatus.loaded, moods: entries),
      onDelete: (_) async {},
    );

    expect(find.text('Tired'), findsOneWidget);
    expect(find.text('Long day at work'), findsOneWidget);
    expect(find.text('5/10'), findsOneWidget);
  });

  testWidgets('delete menu action triggers onDelete callback', (tester) async {
    final entry = buildMood(
      id: 'm-delete',
      score: 4,
      moodType: 'Anxious',
      date: DateTime(2026, 3, 8, 9),
    );

    MoodEntity? deleted;

    await pumpTab(
      tester,
      state: MoodState(status: MoodStatus.loaded, moods: [entry]),
      onDelete: (value) async {
        deleted = value;
      },
    );

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, entry);
  });
}
