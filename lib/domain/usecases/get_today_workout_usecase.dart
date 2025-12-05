import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class GetTodayWorkoutUseCase {
  final WorkoutRepository _repository;
  
  GetTodayWorkoutUseCase(this._repository);
  
  Future<Workout?> call() async {
    final workouts = await _repository.getWorkouts();
    final today = DateTime.now();
    
    try {
      return workouts.firstWhere(
        (w) => w.scheduledDate.year == today.year &&
               w.scheduledDate.month == today.month &&
               w.scheduledDate.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }
}

