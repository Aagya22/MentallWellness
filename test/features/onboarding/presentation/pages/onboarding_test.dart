import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mentalwellness/features/onboarding/presentation/pages/onboarding3rd_screen.dart';
import 'package:mentalwellness/features/onboarding/presentation/pages/onboardingfirst_screen.dart';

void main() {

  testWidgets('Onboarding First Screen should show journal texts',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingfirstScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Journal Your Thoughts'), findsOneWidget);
    expect(
      find.text('Express yourself freely through our journaling app'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
  });



  testWidgets('Onboarding Third Screen should show mood tracker texts',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Onboarding3rdScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mood Tracker'), findsOneWidget);
    expect(
      find.text('Track your mood and feel more aware'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
  });

}