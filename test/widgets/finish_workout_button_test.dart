import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:kinetix_mobile/presentation/widgets/workout/finish_workout_button_widget.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('FinishWorkoutButton', () {
    testWidgets('4.4.1: Prikazuje "Finish" i "Give Up" dugmad', (WidgetTester tester) async {
      // Setup
      final workout = TestHelpers.createMockWorkout();
      final confettiController = ConfettiController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FinishWorkoutButton(
                workout: workout,
                confettiController: confettiController,
                onFinish: () {},
                onGiveUp: () {},
              ),
            ),
          ),
        ),
      );

      // Verify - Both buttons are displayed
      expect(find.text('Finish Workout'), findsOneWidget);
      expect(find.text('Give Up'), findsOneWidget);

      confettiController.dispose();
    });

    testWidgets('4.4.2: Klik na "Finish" → Poziva onFinish callback', (WidgetTester tester) async {
      // Setup
      bool finishCalled = false;
      final workout = TestHelpers.createMockWorkout();
      final confettiController = ConfettiController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FinishWorkoutButton(
                workout: workout,
                confettiController: confettiController,
                onFinish: () {
                  finishCalled = true;
                },
                onGiveUp: () {},
              ),
            ),
          ),
        ),
      );

      // Execute - Tap on "Finish" button
      await tester.tap(find.text('Finish Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify - Callback was called
      expect(finishCalled, true);

      confettiController.dispose();
    });

    testWidgets('4.4.3: Klik na "Give Up" → Poziva onGiveUp callback', (WidgetTester tester) async {
      // Setup
      bool giveUpCalled = false;
      final workout = TestHelpers.createMockWorkout();
      final confettiController = ConfettiController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FinishWorkoutButton(
                workout: workout,
                confettiController: confettiController,
                onFinish: () {},
                onGiveUp: () {
                  giveUpCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Execute - Tap on "Give Up" button
      await tester.tap(find.text('Give Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify - Callback was called
      expect(giveUpCalled, true);

      confettiController.dispose();
    });
  });
}
