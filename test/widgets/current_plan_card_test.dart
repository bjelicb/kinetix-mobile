import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kinetix_mobile/presentation/widgets/plans/current_plan_card.dart';
import 'package:kinetix_mobile/domain/entities/plan.dart';
import 'package:kinetix_mobile/presentation/controllers/plan_controller.dart';

void main() {
  group('CurrentPlanCard Widget Tests', () {
    testWidgets('shows nothing when plan is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPlanProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CurrentPlanCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show nothing (SizedBox.shrink)
      expect(find.text('Current Plan'), findsNothing);
    });

    testWidgets('shows plan when available', (WidgetTester tester) async {
      final testPlan = Plan(
        id: 'plan123',
        name: 'Test Plan',
        difficulty: 'INTERMEDIATE',
        trainerId: 'trainer123',
        workoutDays: [
          WorkoutDay(
            dayOfWeek: 1,
            isRestDay: false,
            name: 'Push Day',
            exercises: [],
            estimatedDuration: 60,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPlanProvider.overrideWith((ref) async => testPlan),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CurrentPlanCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show plan name
      expect(find.text('Test Plan'), findsOneWidget);
      expect(find.text('Current Plan'), findsOneWidget);
    });
  });
}

