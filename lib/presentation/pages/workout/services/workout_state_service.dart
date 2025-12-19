import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../domain/entities/workout.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../presentation/controllers/workout_controller.dart';

/// Service for managing workout state mutations
class WorkoutStateService {
  /// Save weight or reps value with auto-advance logic
  static void saveValue({
    required String field,
    required int exerciseIndex,
    required int setIndex,
    required String value,
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
    required ScrollController scrollController,
    required Map<int, GlobalKey> exerciseKeys,
    required Function(String, int, int, String, Workout) showNumpad,
    required Function(int, int, double?, Workout) showRpePicker,
  }) {
    debugPrint('[WorkoutStateService:Input] ═══════════════════════════════════════');
    debugPrint('[WorkoutStateService:Input] saveValue() START');
    debugPrint('[WorkoutStateService:Input] Field: $field');
    debugPrint('[WorkoutStateService:Input] Exercise: $exerciseIndex, Set: $setIndex');
    debugPrint('[WorkoutStateService:Input] Value: $value');
    
    AppHaptic.medium();

    // Parse value
    final numValue = field == 'weight' ? double.tryParse(value) ?? 0.0 : int.tryParse(value) ?? 0;
    debugPrint('[WorkoutStateService:Input] Parsed value: $numValue');

    // Update workout set
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    debugPrint('[WorkoutStateService:Input] Current set - Weight: ${set.weight}, Reps: ${set.reps}, RPE: ${set.rpe}');

    final updatedSet = WorkoutSet(
      id: set.id,
      weight: field == 'weight' ? numValue as double : set.weight,
      reps: field == 'reps' ? numValue as int : set.reps,
      rpe: set.rpe,
      isCompleted: set.isCompleted,
    );

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    debugPrint('[WorkoutStateService:Input] Saving to repository...');
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
    debugPrint('[WorkoutStateService:Input] ✅ Save complete');

    // Auto-advance: weight -> reps -> RPE -> next set
    if (field == 'weight') {
      // After weight, open reps
      debugPrint('[WorkoutStateService:Input] Auto-advance: Weight saved -> Opening Reps input');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          showNumpad('reps', exerciseIndex, setIndex, set.reps.toString(), updatedWorkout);
        }
      });
    } else if (field == 'reps') {
      // After reps, open RPE
      debugPrint('[WorkoutStateService:Input] Auto-advance: Reps saved -> Opening RPE picker');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          showRpePicker(exerciseIndex, setIndex, set.rpe, updatedWorkout);
        }
      });
    }
    debugPrint('[WorkoutStateService:Input] ═══════════════════════════════════════');
  }

  /// Save RPE value with auto-advance logic
  static void saveRpe({
    required int exerciseIndex,
    required int setIndex,
    required double rpe,
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
    required ScrollController scrollController,
    required Map<int, GlobalKey> exerciseKeys,
    required Function(String, int, int, String, Workout) showNumpad,
  }) {
    debugPrint('[WorkoutStateService:RPE] ═══════════════════════════════════════');
    debugPrint('[WorkoutStateService:RPE] saveRpe() START');
    debugPrint('[WorkoutStateService:RPE] Exercise: $exerciseIndex, Set: $setIndex');
    debugPrint('[WorkoutStateService:RPE] RPE value: $rpe');
    
    AppHaptic.medium();

    // Update workout set
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    debugPrint('[WorkoutStateService:RPE] Current set - Weight: ${set.weight}, Reps: ${set.reps}');

    final updatedSet = WorkoutSet(
      id: set.id,
      weight: set.weight,
      reps: set.reps,
      rpe: rpe,
      isCompleted: set.isCompleted,
    );

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    debugPrint('[WorkoutStateService:RPE] Saving to repository...');
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
    debugPrint('[WorkoutStateService:RPE] ✅ Save complete');

    // Auto-advance: After RPE, move to next set
    final nextSetIndex = setIndex + 1;
    if (nextSetIndex < exercise.sets.length) {
      // Move to next set in same exercise
      debugPrint('[WorkoutStateService:RPE] Auto-advance: Moving to next set ($nextSetIndex) in same exercise');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          final nextSet = exercise.sets[nextSetIndex];
          showNumpad('weight', exerciseIndex, nextSetIndex, nextSet.weight.toString(), updatedWorkout);
        }
      });
    } else {
      // Move to next exercise
      final nextExerciseIndex = exerciseIndex + 1;
      debugPrint('[WorkoutStateService:RPE] All sets complete for this exercise');
      if (nextExerciseIndex < workout.exercises.length) {
        final nextExercise = workout.exercises[nextExerciseIndex];
        if (nextExercise.sets.isNotEmpty) {
          debugPrint('[WorkoutStateService:RPE] Auto-advance: Moving to next exercise ($nextExerciseIndex)');
          // Scroll to next exercise before opening numpad
          Future.delayed(const Duration(milliseconds: 400), () {
            if (context.mounted && scrollController.hasClients) {
              final key = exerciseKeys[nextExerciseIndex];
              if (key != null && key.currentContext != null) {
                Scrollable.ensureVisible(
                  key.currentContext!,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: 0.1, // Slight offset from top
                );
              }
            }
          });

          Future.delayed(const Duration(milliseconds: 700), () {
            if (context.mounted) {
              final nextSet = nextExercise.sets[0];
              showNumpad('weight', nextExerciseIndex, 0, nextSet.weight.toString(), updatedWorkout);
            }
          });
        } else {
          debugPrint('[WorkoutStateService:RPE] Next exercise has no sets');
        }
      } else {
        debugPrint('[WorkoutStateService:RPE] All exercises complete!');
      }
    }
    debugPrint('[WorkoutStateService:RPE] ═══════════════════════════════════════');
  }

  /// Delete a set from workout
  static WorkoutSet? deleteSet({
    required int exerciseIndex,
    required int setIndex,
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    AppHaptic.medium();

    // Store deleted set for undo
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    // Remove set from exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: List<WorkoutSet>.from(exercise.sets)..removeAt(setIndex),
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    // Update workout
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);

    // Return deleted set for undo functionality
    return set;
  }

  /// Undo set deletion
  static void undoDeleteSet({
    required WorkoutSet deletedSet,
    required int exerciseIndex,
    required int setIndex,
    required Workout workout,
    required WidgetRef ref,
  }) {
    AppHaptic.light();

    final exercise = workout.exercises[exerciseIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets.insert(setIndex, deletedSet);

    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
  }

  /// Check if exercise is completed (ALL sets must be completed)
  static bool isExerciseCompleted(Exercise exercise) {
    debugPrint('[WorkoutStateService] Checking exercise "${exercise.name}" completion status');
    if (exercise.sets.isEmpty) {
      debugPrint('[WorkoutStateService] Exercise has no sets - Not completed');
      return false;
    }
    final isCompleted = exercise.sets.every((set) => set.isCompleted);
    debugPrint(
      '[WorkoutStateService] Exercise "${exercise.name}" - ${exercise.sets.where((s) => s.isCompleted).length}/${exercise.sets.length} sets completed - Overall: $isCompleted',
    );
    return isCompleted;
  }

  /// Toggle set completion
  static void toggleSetCompletion({
    required int exerciseIndex,
    required int setIndex,
    required Workout workout,
    required WidgetRef ref,
  }) {
    AppHaptic.selection();

    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    final newCompletedState = !set.isCompleted;

    debugPrint('[WorkoutStateService] Set $setIndex in exercise $exerciseIndex toggle - Current: ${set.isCompleted}, New: $newCompletedState');

    // Create updated set with new completion state
    final updatedSet = WorkoutSet(
      id: set.id,
      weight: set.weight,
      reps: set.reps,
      rpe: set.rpe,
      isCompleted: newCompletedState,
    );

    // Update sets list
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    // Create updated exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    // Create updated workout
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
  }

  /// Toggle exercise completion - toggles ALL sets in the exercise
  static void toggleExerciseCompletion({
    required int exerciseIndex,
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
    required DateTime? workoutStartTime,
    required Function(bool) onFastCompletion,
  }) {
    AppHaptic.selection();

    final exercise = workout.exercises[exerciseIndex];
    final isCurrentlyCompleted = isExerciseCompleted(exercise);
    final newCompletedState = !isCurrentlyCompleted;

    debugPrint('[WorkoutStateService] Exercise $exerciseIndex toggle initiated - Current state: $isCurrentlyCompleted');
    debugPrint('[WorkoutStateService] Updating ${exercise.sets.length} sets to $newCompletedState');

    // Create updated sets with new completion state
    final updatedSets = exercise.sets
        .map(
          (set) =>
              WorkoutSet(id: set.id, weight: set.weight, reps: set.reps, rpe: set.rpe, isCompleted: newCompletedState),
        )
        .toList();

    // Create updated exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    // Create updated workout
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Fast completion validation (only for first exercise, only once)
    if (exerciseIndex == 0 && newCompletedState == true && workoutStartTime != null) {
      final duration = DateTime.now().difference(workoutStartTime);
      debugPrint('[WorkoutStateService] Workout duration: ${duration.inSeconds}s - Threshold: 30s');

      if (duration.inSeconds < 30) {
        debugPrint('[WorkoutStateService] Fast completion detected');
        onFastCompletion(true);
      }
    }

    try {
      // Optimistic UI update + save to repository
      ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
      debugPrint('[WorkoutStateService] Isar DB update SUCCESS');
    } catch (e) {
      // Rollback on error - revert to original state
      debugPrint('[WorkoutStateService] ERROR - Rollback initiated: $e');

      // Revert the workout update
      ref.read(workoutControllerProvider.notifier).updateWorkout(workout);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating exercise: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Finish workout - mark as completed
  static Future<void> finishWorkout({
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
    required ConfettiController confettiController,
  }) async {
    AppHaptic.heavy();

    try {
      // Mark workout as completed
      final updatedWorkout = Workout(
        id: workout.id,
        serverId: workout.serverId,
        name: workout.name,
        scheduledDate: workout.scheduledDate,
        isCompleted: true,
        isMissed: workout.isMissed,
        isRestDay: workout.isRestDay,
        exercises: workout.exercises,
        isDirty: true,
        updatedAt: DateTime.now(),
      );

      // Save to repository
      await ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);

      // Show confetti animation
      confettiController.play();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout completed! Great job!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finishing workout: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}
