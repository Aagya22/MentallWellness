import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_log_tab.dart';

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

  testWidgets('MoodNoteCard shows selected mood label and chip', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpCard(
      tester,
      MoodNoteCard(
        selectedLabel: 'Happy',
        selectedScore: 8,
        noteController: controller,
        disabled: false,
      ),
    );

    expect(find.text('Happy • 8/10'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
  });

  testWidgets('MoodSaveButton shows disabled helper text', (tester) async {
    await pumpCard(
      tester,
      MoodSaveButton(enabled: false, saving: false, onPressed: () {}),
    );

    expect(find.text('Pick a mood first to enable saving.'), findsOneWidget);
    expect(find.text('Save mood'), findsOneWidget);
  });

  testWidgets('MoodSaveButton invokes callback when enabled', (tester) async {
    var tapped = 0;

    await pumpCard(
      tester,
      MoodSaveButton(
        enabled: true,
        saving: false,
        onPressed: () {
          tapped++;
        },
      ),
    );

    await tester.tap(find.text('Save mood'));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('MoodWeeklyOverviewCard shows empty text when no overview exists', (tester) async {
    await pumpCard(
      tester,
      const MoodWeeklyOverviewCard(overview: null),
    );

    expect(find.text('No mood overview yet'), findsOneWidget);
  });
}
