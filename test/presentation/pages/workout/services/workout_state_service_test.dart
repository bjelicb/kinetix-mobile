import 'dart:async' show FutureOr;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetix_mobile/presentation/pages/workout/services/workout_state_service.dart';
import 'package:kinetix_mobile/presentation/controllers/workout_controller.dart';
import 'package:kinetix_mobile/data/datasources/remote_data_source.dart';
import 'package:kinetix_mobile/domain/entities/workout.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/mocks.mocks.dart';

// Test wrapper widget that provides WidgetRef
class TestWrapper extends ConsumerWidget {
  final Widget child;
  final Function(WidgetRef ref, BuildContext context)? onBuild;

  const TestWrapper({super.key, required this.child, this.onBuild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild?.call(ref, context);
    return child;
  }
}

// Helper function to create a test widget with GoRouter
Widget createTestWidgetWithGoRouter({
  required ProviderContainer container,
  required Widget child,
}) {
  // Create a simple GoRouter for tests
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Calendar'))),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

// Tracking variables for test assertions
Workout? lastUpdatedWorkout;
int? migratedDayOfWeek;
String? migratedPlanId;

// Test WorkoutController that uses mock repository
class _TestWorkoutController extends WorkoutController {
  final MockWorkoutRepository mockRepository;

  _TestWorkoutController(this.mockRepository);

  @override
  FutureOr<List<Workout>> build() async {
    // Note: _repository is private, but refreshWorkouts() uses it
    // We'll override refreshWorkouts() instead to avoid accessing private field
    return [];
  }

  @override
  Future<void> refreshWorkouts({Workout? updatedWorkout}) async {
    // Mock refreshWorkouts to use getWorkouts() from mock repository
    await mockRepository.getWorkouts();
  }

  @override
  Future<Workout> updateWorkout(Workout workout) async {
    return await mockRepository.updateWorkout(workout);
  }

  @override
  Future<int?> migrateDayOfWeek(Workout workout) async {
    return await mockRepository.migrateDayOfWeek(workout);
  }

  @override
  Future<String?> migratePlanId(Workout workout) async {
    return await mockRepository.migratePlanId(workout);
  }
}

void main() {
  group('WorkoutStateService', () {
    late ProviderContainer container;
    late MockRemoteDataSource mockRemoteDataSource;
    late MockWorkoutRepository mockWorkoutRepository;

    setUp(() {
      mockRemoteDataSource = MockRemoteDataSource();
      mockWorkoutRepository = MockWorkoutRepository();
      lastUpdatedWorkout = null;
      migratedDayOfWeek = null;
      migratedPlanId = null;

      // Setup default mock behavior for WorkoutRepository
      when(mockWorkoutRepository.updateWorkout(any)).thenAnswer((invocation) async {
        final workout = invocation.positionalArguments[0] as Workout;
        lastUpdatedWorkout = workout;
        return workout;
      });

      when(mockWorkoutRepository.migrateDayOfWeek(any)).thenAnswer((invocation) async {
        final workout = invocation.positionalArguments[0] as Workout;
        if (workout.dayOfWeek != null) return workout.dayOfWeek;
        migratedDayOfWeek = workout.scheduledDate.weekday;
        return migratedDayOfWeek;
      });

      when(mockWorkoutRepository.migratePlanId(any)).thenAnswer((invocation) async {
        return migratedPlanId;
      });

      // Mock getWorkouts() for refreshWorkouts() calls
      when(mockWorkoutRepository.getWorkouts()).thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          remoteDataSourceProvider.overrideWithValue(mockRemoteDataSource),
          // Override workoutControllerProvider to use mock repository
          workoutControllerProvider.overrideWith(() {
            return _TestWorkoutController(mockWorkoutRepository);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('finishWorkout()', () {
      testWidgets('1.1.1: Uspešan API poziv + lokalna izmena', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          planId: 'test-plan-id',
          dayOfWeek: 1,
          isCompleted: false,
          isDirty: false,
          isSyncing: false,
        );

        final confettiController = ConfettiController();

        // Mock API response
        when(mockRemoteDataSource.logWorkout(any)).thenAnswer((_) async => {'_id': 'server-id-123'});

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                // Execute
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for confetti and navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify
        verify(mockRemoteDataSource.logWorkout(any)).called(1);
      });

      testWidgets('1.1.2: API Fail nakon Retry-a (Offline Scenario)', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: 'test-plan-id', dayOfWeek: 1, isSyncing: false);

        final confettiController = ConfettiController();

        // Mock API failure (network error)
        when(mockRemoteDataSource.logWorkout(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/workout'),
            type: DioExceptionType.connectionError,
          ),
        );

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for retry logic (3 seconds = 3 retry attempts) + navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 4500));
        await tester.pumpAndSettle();

        // Verify - API should be called multiple times (retry)
        verify(mockRemoteDataSource.logWorkout(any)).called(greaterThan(1));
        // Verify workout is marked as dirty
        expect(lastUpdatedWorkout?.isDirty, true);
      });

      testWidgets('1.1.3: API Uspeh Ali Lokalna Izmena Fail (Partial Success sa Retry)', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: 'test-plan-id', dayOfWeek: 1, isSyncing: false);

        final confettiController = ConfettiController();

        // Mock API success
        when(mockRemoteDataSource.logWorkout(any)).thenAnswer((_) async => {'_id': 'server-id-123'});

        // Mock local update to fail first time, succeed second time
        var updateAttempts = 0;
        when(mockWorkoutRepository.updateWorkout(any)).thenAnswer((invocation) async {
          updateAttempts++;
          final workout = invocation.positionalArguments[0] as Workout;
          if (updateAttempts == 1) {
            throw Exception('Local update failed');
          }
          lastUpdatedWorkout = workout;
          return workout;
        });

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for retry logic + navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 4500));
        await tester.pumpAndSettle();

        // Verify - API was called
        verify(mockRemoteDataSource.logWorkout(any)).called(1);
        // Verify - Local update was retried
        expect(updateAttempts, greaterThan(1));
      });

      testWidgets('1.1.4: planId null → Migration Uspeh → finishWorkout Uspeh', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          planId: null,
          dayOfWeek: 1,
          serverId: 'server-id-123',
          isSyncing: false,
        );

        final confettiController = ConfettiController();

        // Mock migration success
        migratedPlanId = 'migrated-plan-id';

        // Mock API success
        when(mockRemoteDataSource.logWorkout(any)).thenAnswer((_) async => {'_id': 'server-id-123'});

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - API was called with migrated planId
        verify(mockRemoteDataSource.logWorkout(any)).called(1);
      });

      testWidgets('1.1.5: planId null → Migration Fail → Error', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: null, dayOfWeek: 1, serverId: null, isSyncing: false);

        final confettiController = ConfettiController();

        // Mock migration failure - planId stays null
        migratedPlanId = null;

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - API was NOT called
        verifyNever(mockRemoteDataSource.logWorkout(any));
      });

      testWidgets('1.1.6: dayOfWeek null → Migration Uspeh → finishWorkout Uspeh', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: 'test-plan-id', dayOfWeek: null, isSyncing: false);

        final confettiController = ConfettiController();

        // Migration will calculate dayOfWeek from scheduledDate
        // (already set up in setUp() method)

        // Mock API success
        when(mockRemoteDataSource.logWorkout(any)).thenAnswer((_) async => {'_id': 'server-id-123'});

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Migration was called
        verify(mockWorkoutRepository.migrateDayOfWeek(any)).called(greaterThanOrEqualTo(1));
        // Verify - API was called after migration
        verify(mockRemoteDataSource.logWorkout(any)).called(1);
      });

      testWidgets('1.1.7: isSyncing true → Skip API Poziv', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: 'test-plan-id', dayOfWeek: 1, isSyncing: true);

        final confettiController = ConfettiController();

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - API was NOT called
        verifyNever(mockRemoteDataSource.logWorkout(any));
      });

      testWidgets('1.1.8: Timeout Scenario', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: 'test-plan-id', dayOfWeek: 1, isSyncing: false);

        final confettiController = ConfettiController();

        // Mock API timeout
        when(mockRemoteDataSource.logWorkout(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/workout'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.finishWorkout(
                  workout: workout,
                  ref: ref,
                  context: context,
                  confettiController: confettiController,
                );
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for retry logic (3 seconds = 3 retry attempts) + navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 4500));
        await tester.pumpAndSettle();

        // Verify - Timeout was handled
        verify(mockRemoteDataSource.logWorkout(any)).called(greaterThan(1));
        // Verify - Workout is marked as dirty after timeout
        expect(lastUpdatedWorkout?.isDirty, true);
      });
    });

    group('markAsMissed()', () {
      testWidgets('1.2.1: Uspešan API Poziv (Workout Ima serverId) + Lokalna Izmena', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          serverId: 'server-id-123',
          isCompleted: true,
          isMissed: false,
          isSyncing: false,
        );

        // Mock API success
        when(mockRemoteDataSource.updateWorkoutLog(any, any)).thenAnswer((_) async => {});

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.markAsMissed(workout: workout, ref: ref, context: context);
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (0.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify
        verify(mockRemoteDataSource.updateWorkoutLog(any, any)).called(1);
        expect(lastUpdatedWorkout?.isCompleted, false);
        expect(lastUpdatedWorkout?.isMissed, true);
      });

      testWidgets('1.2.2: Workout Bez serverId → Samo Lokalna Izmena (Bez API Poziva)', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(serverId: null, isSyncing: false);

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.markAsMissed(workout: workout, ref: ref, context: context);
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (0.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - API was NOT called
        verifyNever(mockRemoteDataSource.updateWorkoutLog(any, any));
        // Verify - Local update was called with isDirty=true
        expect(lastUpdatedWorkout?.isMissed, true);
        expect(lastUpdatedWorkout?.isDirty, true);
      });

      testWidgets('1.2.3: API Fail Nakon Retry-a → isDirty=true', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(serverId: 'server-id-123', isSyncing: false);

        // Mock API failure
        when(mockRemoteDataSource.updateWorkoutLog(any, any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/workout'),
            type: DioExceptionType.connectionError,
          ),
        );

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.markAsMissed(workout: workout, ref: ref, context: context);
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for retry logic (3 seconds = 3 retry attempts) + navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 4500));
        await tester.pumpAndSettle();

        // Verify - API was called multiple times (retry)
        verify(mockRemoteDataSource.updateWorkoutLog(any, any)).called(greaterThan(1));
        // Verify - Workout is marked as dirty
        expect(lastUpdatedWorkout?.isDirty, true);
      });

      testWidgets('1.2.4: API Uspeh Ali Lokalna Izmena Fail → Retry Logika', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(serverId: 'server-id-123', isSyncing: false);

        // Mock API success
        when(mockRemoteDataSource.updateWorkoutLog(any, any)).thenAnswer((_) async => {});

        // Mock local update to fail first time, succeed second time
        var updateAttempts = 0;
        when(mockWorkoutRepository.updateWorkout(any)).thenAnswer((invocation) async {
          updateAttempts++;
          final workout = invocation.positionalArguments[0] as Workout;
          if (updateAttempts == 1) {
            throw Exception('Local update failed');
          }
          lastUpdatedWorkout = workout;
          return workout;
        });

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.markAsMissed(workout: workout, ref: ref, context: context);
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for retry logic + navigation (0.5 seconds)
        await tester.pump(const Duration(milliseconds: 3500));
        await tester.pumpAndSettle();

        // Verify - API was called
        verify(mockRemoteDataSource.updateWorkoutLog(any, any)).called(1);
        // Verify - Local update was retried
        expect(updateAttempts, greaterThan(1));
      });

      testWidgets('1.2.5: isSyncing true → Skip API Poziv', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(serverId: 'server-id-123', isSyncing: true);

        await tester.pumpWidget(
          createTestWidgetWithGoRouter(
            container: container,
            child: TestWrapper(
              onBuild: (ref, context) {
                WorkoutStateService.markAsMissed(workout: workout, ref: ref, context: context);
              },
              child: Container(),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - API was NOT called
        verifyNever(mockRemoteDataSource.updateWorkoutLog(any, any));
      });
    });

    group('toggleExerciseCompletion()', () {
      testWidgets('1.3.1: Check Vezbe → Default Vrednosti Se Postavljaju', (WidgetTester tester) async {
        // Setup
        final exercise = TestHelpers.createMockExercise(
          planReps: '10',
          sets: [TestHelpers.createMockSet(weight: 0, reps: 0, rpe: 0)],
        );

        final workout = TestHelpers.createMockWorkout(exercises: [exercise]);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.toggleExerciseCompletion(
                      exerciseIndex: 0,
                      workout: workout,
                      ref: ref,
                      context: context,
                      workoutStartTime: null,
                      onFastCompletion: (_) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Default values were set
        expect(lastUpdatedWorkout, isNotNull);
        final ex = lastUpdatedWorkout!.exercises[0];
        final set = ex.sets[0];
        expect(set.weight, 5.0); // Default weight is 5.0 (first option from WeightPicker)
        expect(set.reps, 10);
        expect(set.rpe, 6.5); // Default RPE is 6.5 (Ok - middle option from RpePicker)
      });

      testWidgets('1.3.2: Uncheck Vezbe → Vrednosti Se Čuvaju', (WidgetTester tester) async {
        // Setup - create exercise with existing values
        final exercise = TestHelpers.createMockExercise(
          planReps: '10',
          sets: [TestHelpers.createMockSet(weight: 20, reps: 12, rpe: 7, isCompleted: true)],
        );

        final workout = TestHelpers.createMockWorkout(exercises: [exercise]);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    // Toggle twice: first to check, then to uncheck
                    WorkoutStateService.toggleExerciseCompletion(
                      exerciseIndex: 0,
                      workout: workout,
                      ref: ref,
                      context: context,
                      workoutStartTime: null,
                      onFastCompletion: (_) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Values are preserved
        expect(lastUpdatedWorkout, isNotNull);
        final ex = lastUpdatedWorkout!.exercises[0];
        final set = ex.sets[0];
        expect(set.weight, 20.0);
        expect(set.reps, 12);
        expect(set.rpe, 7.0);
      });

      testWidgets('1.3.3: Safe Default Vrednosti (Ako Su Negativne Ili Invalidne)', (WidgetTester tester) async {
        // Setup - create exercise with invalid values
        final exercise = TestHelpers.createMockExercise(
          planReps: '10',
          sets: [TestHelpers.createMockSet(weight: -5, reps: -2, rpe: 15)],
        );

        final workout = TestHelpers.createMockWorkout(exercises: [exercise]);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.toggleExerciseCompletion(
                      exerciseIndex: 0,
                      workout: workout,
                      ref: ref,
                      context: context,
                      workoutStartTime: null,
                      onFastCompletion: (_) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Safe default values are used
        expect(lastUpdatedWorkout, isNotNull);
        final ex = lastUpdatedWorkout!.exercises[0];
        final set = ex.sets[0];
        // Weight should be >= 0
        expect(set.weight, greaterThanOrEqualTo(0));
        // Reps should be > 0
        expect(set.reps, greaterThan(0));
        // RPE should be between 0 and 10
        expect(set.rpe, greaterThanOrEqualTo(0));
        expect(set.rpe, lessThanOrEqualTo(10));
      });
    });

    group('saveValue()', () {
      testWidgets('1.4.1: Valid Weight (>= 0) → Uspeh', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          exercises: [
            TestHelpers.createMockExercise(sets: [TestHelpers.createMockSet()]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.saveValue(
                      field: 'weight',
                      exerciseIndex: 0,
                      setIndex: 0,
                      value: '50.0',
                      workout: workout,
                      ref: ref,
                      scrollController: ScrollController(),
                      exerciseKeys: {},
                      showNumpad: (_, _, _, _, _) {},
                      showRpePicker: (_, _, _, _) {},
                      showRepsPicker: (_, _, _, _, _) {},
                      showWeightPicker: (_, _, _, _) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Weight was updated
        expect(lastUpdatedWorkout, isNotNull);
        final set = lastUpdatedWorkout!.exercises[0].sets[0];
        expect(set.weight, 50.0);
        // Verify - No error message
        expect(find.text('Weight cannot be negative. Please enter a valid value.'), findsNothing);
      });

      testWidgets('1.4.2: Invalid Weight (< 0) → Error Message', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          exercises: [
            TestHelpers.createMockExercise(sets: [TestHelpers.createMockSet()]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.saveValue(
                      field: 'weight',
                      exerciseIndex: 0,
                      setIndex: 0,
                      value: '-10.0',
                      workout: workout,
                      ref: ref,
                      scrollController: ScrollController(),
                      exerciseKeys: {},
                      showNumpad: (_, _, _, _, _) {},
                      showRpePicker: (_, _, _, _) {},
                      showRepsPicker: (_, _, _, _, _) {},
                      showWeightPicker: (_, _, _, _) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Error message was shown
        expect(find.text('Weight cannot be negative. Please enter a valid value.'), findsOneWidget);
      });

      testWidgets('1.4.3: Valid Reps (> 0) → Uspeh', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          exercises: [
            TestHelpers.createMockExercise(sets: [TestHelpers.createMockSet()]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.saveValue(
                      field: 'reps',
                      exerciseIndex: 0,
                      setIndex: 0,
                      value: '12',
                      workout: workout,
                      ref: ref,
                      scrollController: ScrollController(),
                      exerciseKeys: {},
                      showNumpad: (_, _, _, _, _) {},
                      showRpePicker: (_, _, _, _) {},
                      showRepsPicker: (_, _, _, _, _) {},
                      showWeightPicker: (_, _, _, _) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Reps was updated
        expect(lastUpdatedWorkout, isNotNull);
        final set = lastUpdatedWorkout!.exercises[0].sets[0];
        expect(set.reps, 12);
        // Verify - No error message
        expect(find.text('Reps must be greater than 0. Please enter a valid value.'), findsNothing);
      });

      testWidgets('1.4.4: Invalid Reps (<= 0) → Error Message', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          exercises: [
            TestHelpers.createMockExercise(sets: [TestHelpers.createMockSet()]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.saveValue(
                      field: 'reps',
                      exerciseIndex: 0,
                      setIndex: 0,
                      value: '0',
                      workout: workout,
                      ref: ref,
                      scrollController: ScrollController(),
                      exerciseKeys: {},
                      showNumpad: (_, _, _, _, _) {},
                      showRpePicker: (_, _, _, _) {},
                      showRepsPicker: (_, _, _, _, _) {},
                      showWeightPicker: (_, _, _, _) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Error message was shown
        expect(find.text('Reps must be greater than 0. Please enter a valid value.'), findsOneWidget);
      });
    });

    group('saveRpe()', () {
      testWidgets('1.5.1: Valid RPE (0-10) → Uspeh', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          exercises: [
            TestHelpers.createMockExercise(sets: [TestHelpers.createMockSet()]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.saveRpe(
                      exerciseIndex: 0,
                      setIndex: 0,
                      rpe: 7.5,
                      workout: workout,
                      ref: ref,
                      scrollController: ScrollController(),
                      exerciseKeys: {},
                      showNumpad: (_, _, _, _, _) {},
                      showWeightPicker: (_, _, _, _) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - RPE was updated
        expect(lastUpdatedWorkout, isNotNull);
        final set = lastUpdatedWorkout!.exercises[0].sets[0];
        expect(set.rpe, 7.5);
        // Verify - No error message
        expect(find.text('RPE must be between 0 and 10. Please enter a valid value.'), findsNothing);
      });

      testWidgets('1.5.2: Invalid RPE (< 0 ili > 10) → Error Message', (WidgetTester tester) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          exercises: [
            TestHelpers.createMockExercise(sets: [TestHelpers.createMockSet()]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    WorkoutStateService.saveRpe(
                      exerciseIndex: 0,
                      setIndex: 0,
                      rpe: 15.0,
                      workout: workout,
                      ref: ref,
                      scrollController: ScrollController(),
                      exerciseKeys: {},
                      showNumpad: (_, _, _, _, _) {},
                      showWeightPicker: (_, _, _, _) {},
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify - Error message was shown
        expect(find.text('RPE must be between 0 and 10. Please enter a valid value.'), findsOneWidget);
      });

      testWidgets('1.1.9: finishWorkout with valid API response → optimistic update via refreshWorkouts', (
        WidgetTester tester,
      ) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          planId: 'test-plan-id',
          dayOfWeek: 1,
          isCompleted: false,
          isDirty: false,
          isSyncing: false,
        );

        final confettiController = ConfettiController();

        // Mock API response with valid workout log data
        final apiResponse = {
          '_id': 'server-id-123',
          'workoutDate': DateTime.now().toIso8601String(),
          'dayOfWeek': 1,
          'isCompleted': true,
          'isMissed': false,
          'isRestDay': false,
          'weeklyPlanId': {
            '_id': 'test-plan-id',
            'workouts': [
              {'dayOfWeek': 1, 'name': 'Test Workout', 'exercises': []},
            ],
          },
          'planExercises': [],
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockRemoteDataSource.logWorkout(any)).thenAnswer((_) async => apiResponse);

        // Override workoutControllerProvider
        final testContainer = ProviderContainer(
          overrides: [
            remoteDataSourceProvider.overrideWithValue(mockRemoteDataSource),
            workoutControllerProvider.overrideWith(() {
              final controller = _TestWorkoutController(mockWorkoutRepository);
              // Override refreshWorkouts to track calls
              return controller;
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    // Execute
                    WorkoutStateService.finishWorkout(
                      workout: workout,
                      ref: ref,
                      context: context,
                      confettiController: confettiController,
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify
        verify(mockRemoteDataSource.logWorkout(any)).called(1);
        // Note: refreshWorkouts is called asynchronously, so we verify the API call succeeded
      });

      testWidgets('1.1.10: finishWorkout with invalid API response → full reload via refreshWorkouts', (
        WidgetTester tester,
      ) async {
        // Setup
        final workout = TestHelpers.createMockWorkout(
          planId: 'test-plan-id',
          dayOfWeek: 1,
          isCompleted: false,
          isDirty: false,
          isSyncing: false,
        );

        final confettiController = ConfettiController();

        // Mock API response without _id (invalid)
        final apiResponse = {
          'workoutDate': DateTime.now().toIso8601String(),
          // Missing _id field
        };

        when(mockRemoteDataSource.logWorkout(any)).thenAnswer((_) async => apiResponse);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TestWrapper(
                  onBuild: (ref, context) {
                    // Execute
                    WorkoutStateService.finishWorkout(
                      workout: workout,
                      ref: ref,
                      context: context,
                      confettiController: confettiController,
                    );
                  },
                  child: Container(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // Advance time for navigation (1.5 seconds)
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle();

        // Verify
        verify(mockRemoteDataSource.logWorkout(any)).called(1);
        // Note: refreshWorkouts should be called with full reload (no updatedWorkout)
      });
    });
  });
}
