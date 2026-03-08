import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('MoodSectionTitle renders title text', (tester) async {
    await pumpCard(
      tester,
      const MoodSectionTitle(icon: Icons.mood, title: 'Pick your mood'),
    );

    expect(find.text('Pick your mood'), findsOneWidget);
  });

  testWidgets('MoodSectionTitle renders leading icon', (tester) async {
    await pumpCard(
      tester,
      const MoodSectionTitle(icon: Icons.edit_note_outlined, title: 'Note'),
    );

    expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
  });

  testWidgets('MoodMetricCard renders title and value', (tester) async {
    await pumpCard(
      tester,
      const MoodMetricCard(
        title: 'Average',
        value: 'Good\n7.2/10',
        icon: Icons.insights_rounded,
      ),
    );

    expect(find.text('Average'), findsOneWidget);
    expect(find.text('Good\n7.2/10'), findsOneWidget);
  });

  testWidgets('MoodMetricCard renders supplied icon', (tester) async {
    await pumpCard(
      tester,
      const MoodMetricCard(
        title: 'Logged',
        value: '5\nthis week',
        icon: Icons.check_circle_outline,
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
