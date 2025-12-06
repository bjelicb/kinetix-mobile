import '../entities/workout.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> getWorkouts();
  Future<Workout?> getWorkoutById(String id);
  Future<Workout> createWorkout(Workout workout);
  Future<Workout> updateWorkout(Workout workout);
  Future<void> deleteWorkout(String id);
  Future<void> logSet(String workoutId, String exerciseId, double weight, int reps, double? rpe);
}

