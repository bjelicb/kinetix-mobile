import '../repositories/workout_repository.dart';

class LogSetUseCase {
  final WorkoutRepository _repository;
  
  LogSetUseCase(this._repository);
  
  Future<void> call(String workoutId, String exerciseId, double weight, int reps, double? rpe) async {
    await _repository.logSet(workoutId, exerciseId, weight, reps, rpe);
  }
}

