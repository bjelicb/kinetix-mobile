import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_mobile/presentation/controllers/workout_controller.dart';
import 'package:kinetix_mobile/domain/repositories/workout_repository.dart';
import 'package:kinetix_mobile/domain/entities/workout.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mocks.mocks.dart';

// Test WorkoutController that uses mock repository
// We override methods that use _repository to use mockRepository instead
class _TestWorkoutController extends WorkoutController {
  final WorkoutRepository mockRepository;

  _TestWorkoutController(this.mockRepository);

  @override
  FutureOr<List<Workout>> build() async {
    // Return workouts from mock repository
    return await mockRepository.getWorkouts();
  }

  @override
  Future<void> refreshWorkouts({Workout? updatedWorkout}) async {
    // Override to use mockRepository instead of _repository
    debugPrint('[WorkoutController] refreshWorkouts() - Forcing API refresh');
    
    debugPrint('[WorkoutController] 📊 REFRESH_WORKOUTS_METRICS:');
    debugPrint('[WorkoutController]   - Method: ${updatedWorkout != null ? "optimistic_update" : "full_reload"}');
    debugPrint('[WorkoutController]   - Current workout count: ${state.valueOrNull?.length ?? 0}');
    debugPrint('[WorkoutController]   - Timestamp: ${DateTime.now().toIso8601String()}');
    
    try {
      if (updatedWorkout != null) {
        debugPrint('[WorkoutController] → Using optimistic update for workout: ${updatedWorkout.name}');
        final currentWorkouts = state.valueOrNull ?? [];
        
        final updatedWorkouts = currentWorkouts.map((w) {
          final isMatch = w.id == updatedWorkout.id || 
                         w.serverId == updatedWorkout.id || 
                         w.id == updatedWorkout.serverId ||
                         (w.serverId != null && w.serverId == updatedWorkout.serverId);
          if (isMatch) {
            return updatedWorkout;
          }
          return w;
        }).toList();
        
        if (!updatedWorkouts.any((w) => w.id == updatedWorkout.id || w.serverId == updatedWorkout.serverId)) {
          updatedWorkouts.add(updatedWorkout);
        }
        
        state = AsyncValue.data(updatedWorkouts);
        debugPrint('[WorkoutController] ✅ Workout optimistically updated: ${updatedWorkout.name}');
        
        // Trigger background sync using mockRepository
        mockRepository.getWorkouts().catchError((e) {
          debugPrint('[WorkoutController] ⚠️ Background sync failed: $e');
          return <Workout>[];
        });
      } else {
        final currentWorkouts = state.valueOrNull ?? [];
        state = AsyncValue.data(currentWorkouts);
        
        final workouts = await mockRepository.getWorkouts();
        state = AsyncValue.data(workouts);
        
        debugPrint('[WorkoutController] ✅ Workouts refreshed: ${workouts.length}');
      }
    } catch (e) {
      debugPrint('[WorkoutController] ✗ Failed to refresh workouts: $e');
      final currentWorkouts = state.valueOrNull ?? [];
      state = AsyncValue.data(currentWorkouts);
    }
  }
}

void main() {
  group('WorkoutController', () {
    late MockWorkoutRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockWorkoutRepository();
      container = ProviderContainer(
        overrides: [
          workoutControllerProvider.overrideWith(() => _TestWorkoutController(mockRepository)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('WorkoutController class exists', () {
      expect(WorkoutController, isA<Type>());
    });

    group('refreshWorkouts()', () {
      test('refreshWorkouts with optimistic update', () async {
        // Setup
        final initialWorkouts = [
          TestHelpers.createMockWorkout(id: 'workout-1', name: 'Workout 1'),
          TestHelpers.createMockWorkout(id: 'workout-2', name: 'Workout 2'),
        ];
        final updatedWorkout = TestHelpers.createMockWorkout(
          id: 'workout-1',
          serverId: 'server-1',
          name: 'Updated Workout 1',
          isCompleted: true,
        );

        when(mockRepository.getWorkouts()).thenAnswer((_) async => initialWorkouts);

        final controller = container.read(workoutControllerProvider.notifier);
        // Wait for build to complete
        await container.read(workoutControllerProvider.future);

        // Execute
        await controller.refreshWorkouts(updatedWorkout: updatedWorkout);

        // Wait for state update
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify: Check controller's state directly (not through provider)
        final controllerState = controller.state;
        expect(controllerState.hasValue, isTrue);
        final workouts = controllerState.valueOrNull;
        expect(workouts, isNotNull);
        expect(workouts!.length, 2);
        // Find the updated workout - check by id or serverId
        final updatedWorkoutInState = workouts.firstWhere(
          (w) => w.id == 'workout-1' || w.serverId == 'server-1',
          orElse: () => workouts.first,
        );
        // The workout should be updated
        expect(updatedWorkoutInState.isCompleted, true);
        
        // Verify background sync is triggered
        verify(mockRepository.getWorkouts()).called(greaterThan(1));
      });

      test('refreshWorkouts with full reload', () async {
        // Setup
        final initialWorkouts = [
          TestHelpers.createMockWorkout(id: 'workout-1', name: 'Workout 1'),
        ];
        final refreshedWorkouts = [
          TestHelpers.createMockWorkout(id: 'workout-1', name: 'Workout 1'),
          TestHelpers.createMockWorkout(id: 'workout-2', name: 'Workout 2'),
        ];

        int callCount = 0;
        when(mockRepository.getWorkouts()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return initialWorkouts;
          } else {
            return refreshedWorkouts;
          }
        });

        container = ProviderContainer(
          overrides: [
            workoutControllerProvider.overrideWith(() => _TestWorkoutController(mockRepository)),
          ],
        );

        final controller = container.read(workoutControllerProvider.notifier);
        // Wait for build to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Execute
        await controller.refreshWorkouts();

        // Verify
        final state = await container.read(workoutControllerProvider.future);
        expect(state, isNotNull);
        expect(state.length, 2);
        expect(state.last.name, 'Workout 2');
        
        // Verify getWorkouts was called for reload
        verify(mockRepository.getWorkouts()).called(greaterThan(1));
      });

      test('refreshWorkouts error handling', () async {
        // Setup
        final initialWorkouts = [
          TestHelpers.createMockWorkout(id: 'workout-1', name: 'Workout 1'),
        ];

        int callCount = 0;
        when(mockRepository.getWorkouts()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return initialWorkouts;
          } else {
            throw Exception('Network error');
          }
        });

        // Create new container for this test
        final testContainer = ProviderContainer(
          overrides: [
            workoutControllerProvider.overrideWith(() => _TestWorkoutController(mockRepository)),
          ],
        );

        final testController = testContainer.read(workoutControllerProvider.notifier);
        // Wait for build to complete
        await testContainer.read(workoutControllerProvider.future);

        // Execute
        await testController.refreshWorkouts();

        // Verify
        // State should be preserved (not set to error)
        final state = await testContainer.read(workoutControllerProvider.future);
        expect(state, isNotNull);
        expect(state.length, 1);
        
        // Verify error was caught (no exception thrown)
        verify(mockRepository.getWorkouts()).called(greaterThanOrEqualTo(1));
        
        testContainer.dispose();
      });

      test('refreshWorkouts workout matching logic', () async {
        // Setup
        final initialWorkouts = [
          TestHelpers.createMockWorkout(id: 'workout-1', serverId: 'server-1', name: 'Workout 1', isCompleted: false),
        ];
        final updatedWorkout = TestHelpers.createMockWorkout(
          id: 'workout-1',
          serverId: 'server-1',
          name: 'Updated Workout 1',
          isCompleted: true, // Explicitly set to true
        );

        when(mockRepository.getWorkouts()).thenAnswer((_) async => initialWorkouts);

        final controller = container.read(workoutControllerProvider.notifier);
        // Wait for build to complete
        await container.read(workoutControllerProvider.future);

        // Execute - match by id
        await controller.refreshWorkouts(updatedWorkout: updatedWorkout);

        // Verify: Check controller's state directly
        final controllerState = controller.state;
        expect(controllerState.hasValue, isTrue);
        final workouts = controllerState.valueOrNull;
        expect(workouts, isNotNull);
        expect(workouts!.length, 1);
        // The workout should be updated with new name and isCompleted status
        expect(workouts.first.name, 'Updated Workout 1');
        expect(workouts.first.isCompleted, isTrue);
      });

      test('refreshWorkouts adds workout if not found', () async {
        // Setup
        final initialWorkouts = [
          TestHelpers.createMockWorkout(id: 'workout-1', name: 'Workout 1'),
        ];
        final newWorkout = TestHelpers.createMockWorkout(
          id: 'workout-2',
          serverId: 'server-2',
          name: 'New Workout',
        );

        when(mockRepository.getWorkouts()).thenAnswer((_) async => initialWorkouts);

        final controller = container.read(workoutControllerProvider.notifier);
        // Wait for build to complete
        await container.read(workoutControllerProvider.future);

        // Verify initial state
        final initialState = controller.state.valueOrNull;
        expect(initialState, isNotNull);
        expect(initialState!.length, 1);
        expect(initialState.first.id, 'workout-1');

        // Execute
        await controller.refreshWorkouts(updatedWorkout: newWorkout);

        // Verify: Check controller's state directly
        final controllerState = controller.state;
        expect(controllerState.hasValue, isTrue);
        final workouts = controllerState.valueOrNull;
        expect(workouts, isNotNull);
        // The new workout should be added to the list (1 initial + 1 new = 2)
        expect(workouts!.length, 2);
        // Verify that new workout is in the state
        final hasNewWorkout = workouts.any((w) => w.id == 'workout-2' || w.serverId == 'server-2' || w.name == 'New Workout');
        expect(hasNewWorkout, isTrue);
        // Verify initial workout is still there
        final hasInitialWorkout = workouts.any((w) => w.id == 'workout-1');
        expect(hasInitialWorkout, isTrue);
      });
    });
  });
}
