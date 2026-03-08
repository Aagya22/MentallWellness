import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_empty_section_card.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_greeting_card.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_quick_actions_section.dart';
import 'package:mentalwellness/features/dashboard/presentation/widgets/home_section_header.dart';

void main() {
  Future<void> pumpWidgetWithScaffold(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('HomeSectionHeader shows title and handles See all tap', (tester) async {
    var tapCount = 0;

    await pumpWidgetWithScaffold(
      tester,
      HomeSectionHeader(
        title: 'Reminders',
        onSeeMore: () {
          tapCount++;
        },
      ),
    );

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);

    await tester.tap(find.text('See all'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('HomeEmptySectionCard shows data and handles tap', (tester) async {
    var tapped = false;

    await pumpWidgetWithScaffold(
      tester,
      HomeEmptySectionCard(
        icon: Icons.event_note,
        message: 'No reminders yet',
        ctaText: 'Create reminder',
        onTap: () {
          tapped = true;
        },
      ),
    );

    expect(find.text('No reminders yet'), findsOneWidget);
    expect(find.text('Create reminder'), findsOneWidget);

    await tester.tap(find.text('No reminders yet'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('HomeGreetingCard displays CTA and triggers tap callback', (tester) async {
    var logMoodTapped = 0;

    await pumpWidgetWithScaffold(
      tester,
      HomeGreetingCard(
        headerDate: 'SUNDAY, MAR 8',
        greeting: 'Good Morning',
        userName: 'Aagya',
        onTapLogMood: () {
          logMoodTapped++;
        },
      ),
    );

    expect(find.text('Good Morning,'), findsOneWidget);
    expect(find.text('Aagya'), findsOneWidget);
    expect(find.text('Log your mood today'), findsOneWidget);

    await tester.tap(find.text('Log your mood today'));
    await tester.pump();

    expect(logMoodTapped, 1);
  });

  testWidgets('HomeQuickActionsSection triggers journal and exercise callbacks', (tester) async {
    var journalTapped = 0;
    var exercisesTapped = 0;

    await pumpWidgetWithScaffold(
      tester,
      HomeQuickActionsSection(
        onTapJournal: () {
          journalTapped++;
        },
        onTapExercises: () {
          exercisesTapped++;
        },
      ),
    );

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pump();

    await tester.tap(find.text('Exercises'));
    await tester.pump();

    expect(journalTapped, 1);
    expect(exercisesTapped, 1);
  });
}
