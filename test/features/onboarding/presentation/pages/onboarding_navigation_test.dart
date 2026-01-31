import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mentalwellness/features/landing/presentation/pages/Landing_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboarding2nd_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboarding3rd_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboardingfirst_screen.dart';

void main() {

  testWidgets(
      'Onboarding First - Next navigates to Onboarding Second',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/Onboarding2ndScreen': (_) => const Onboarding2ndScreen(),
        },
        home: const OnboardingfirstScreen(),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(Onboarding2ndScreen), findsOneWidget);
  });

  testWidgets(
      'Onboarding First - SKIP navigates to LandingScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => const OnboardingfirstScreen(),
        ),
      ),
    );

    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets(
      'Onboarding Second - Next navigates to Onboarding Third',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/Onboarding3rdScreen': (_) => const Onboarding3rdScreen(),
        },
        home: const Onboarding2ndScreen(),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(Onboarding3rdScreen), findsOneWidget);
  });

  testWidgets(
      'Onboarding Second - SKIP navigates to LandingScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => const Onboarding2ndScreen(),
        ),
      ),
    );

    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets(
      'Onboarding Third - Next navigates to LandingScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/LandingScreen': (_) => const LandingScreen(),
        },
        home: const Onboarding3rdScreen(),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets(
      'Onboarding Third - SKIP navigates to LandingScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => const Onboarding3rdScreen(),
        ),
      ),
    );

    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
  });
}