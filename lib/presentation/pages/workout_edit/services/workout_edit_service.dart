import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/workout.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../presentation/controllers/workout_controller.dart';

/// Service for workout edit business logic
class WorkoutEditService {
  /// Load workout by ID from workouts list
  static Workout? loadWorkout(String workoutId, List<Workout> workouts) {
    try {
      return workouts.firstWhere(
        (w) => w.id == workoutId,
      );
    } catch (e) {
      throw Exception('Workout not found');
    }
  }

  /// Save workout (create or update)
  static Future<void> saveWorkout(
    Workout workout,
    bool isEdit,
    WidgetRef ref,
  ) async {
    if (isEdit) {
      await ref.read(workoutControllerProvider.notifier).updateWorkout(workout);
    } else {
      await ref.read(workoutControllerProvider.notifier).createWorkout(workout);
    }
  }

  /// Validate workout data
  /// Returns error message if invalid, null if valid
  static String? validateWorkout(String name, List<Exercise> exercises) {
    if (name.trim().isEmpty) {
      return 'Please enter a workout name';
    }
    if (exercises.isEmpty) {
      return 'Please add at least one exercise';
    }
    return null;
  }
}

