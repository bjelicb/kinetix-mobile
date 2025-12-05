import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';

part 'workout_controller.g.dart';

@riverpod
class WorkoutController extends _$WorkoutController {
  late WorkoutRepository _repository;
  
  @override
  FutureOr<List<Workout>> build() async {
    final localDataSource = LocalDataSource();
    // Use null for RemoteDataSource - backend not ready, using mock/offline mode
    _repository = WorkoutRepositoryImpl(localDataSource, null);
    
    return await _repository.getWorkouts();
  }
  
  Future<void> logSet(String workoutId, String exerciseId, double weight, int reps, double? rpe) async {
    await _repository.logSet(workoutId, exerciseId, weight, reps, rpe);
    // Refresh workouts
    state = AsyncValue.data(await _repository.getWorkouts());
  }
  
  Future<Workout> createWorkout(Workout workout) async {
    final created = await _repository.createWorkout(workout);
    state = AsyncValue.data(await _repository.getWorkouts());
    return created;
  }
  
  Future<Workout> updateWorkout(Workout workout) async {
    final updated = await _repository.updateWorkout(workout);
    state = AsyncValue.data(await _repository.getWorkouts());
    return updated;
  }
  
  Future<void> deleteWorkout(String id) async {
    await _repository.deleteWorkout(id);
    state = AsyncValue.data(await _repository.getWorkouts());
  }
}

