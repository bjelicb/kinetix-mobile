import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../mappers/workout_mapper.dart';
import '../mappers/exercise_mapper.dart';
import '../models/workout_collection.dart' if (dart.library.html) '../models/workout_collection_stub.dart';
import '../models/exercise_collection.dart' if (dart.library.html) '../models/exercise_collection_stub.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final LocalDataSource _localDataSource;
  // RemoteDataSource reserved for future direct API calls
  // ignore: unused_field
  final RemoteDataSource? _remoteDataSource;
  
  WorkoutRepositoryImpl(this._localDataSource, this._remoteDataSource);
  
  @override
  Future<List<Workout>> getWorkouts() async {
    final List<WorkoutCollection> collections = await _localDataSource.getWorkouts();
    final workouts = <Workout>[];
    
    for (final WorkoutCollection collection in collections) {
      final List<ExerciseCollection> exercises = await _localDataSource.getExercisesForWorkout(collection.id);
      final exerciseEntities = exercises.map((e) => ExerciseMapper.toEntity(e)).toList();
      workouts.add(WorkoutMapper.toEntity(collection, exerciseEntities));
    }
    
    return workouts;
  }
  
  @override
  Future<Workout?> getWorkoutById(String id) async {
    final isarId = int.tryParse(id);
    if (isarId == null) return null;
    
    final WorkoutCollection? collection = await _localDataSource.getWorkoutById(isarId);
    if (collection == null) return null;
    
    final List<ExerciseCollection> exercises = await _localDataSource.getExercisesForWorkout(collection.id);
    final exerciseEntities = exercises.map((e) => ExerciseMapper.toEntity(e)).toList();
    return WorkoutMapper.toEntity(collection, exerciseEntities);
  }
  
  @override
  Future<Workout> createWorkout(Workout workout) async {
    final collection = WorkoutMapper.toCollection(workout);
    collection.isDirty = true;
    collection.updatedAt = DateTime.now();
    
    await _localDataSource.saveWorkout(collection);
    
    // Trigger background sync
    // Sync will happen in background
    
    return workout;
  }
  
  @override
  Future<Workout> updateWorkout(Workout workout) async {
    final isarId = int.tryParse(workout.id);
    if (isarId == null) throw Exception('Invalid workout ID');
    
    final collection = WorkoutMapper.toCollection(workout, isarId: isarId);
    collection.isDirty = true;
    collection.updatedAt = DateTime.now();
    
    await _localDataSource.saveWorkout(collection);
    
    return workout;
  }
  
  @override
  Future<void> deleteWorkout(String id) async {
    final isarId = int.tryParse(id);
    if (isarId == null) throw Exception('Invalid workout ID');
    await _localDataSource.deleteWorkout(isarId);
  }
  
  @override
  Future<void> logSet(String workoutId, String exerciseId, double weight, int reps, double? rpe) async {
    final isarId = int.tryParse(workoutId);
    if (isarId == null) throw Exception('Invalid workout ID');
    
    final WorkoutCollection? workout = await _localDataSource.getWorkoutById(isarId);
    if (workout == null) throw Exception('Workout not found');
    
    final List<ExerciseCollection> exercises = await _localDataSource.getExercisesForWorkout(workout.id);
    // Verify exercise exists - implementation for adding set will be added later
    exercises.firstWhere((e) => e.id.toString() == exerciseId, orElse: () => throw Exception('Exercise not found'));
    
    // Add new set
    // Implementation for adding set
    
    workout.isDirty = true;
    workout.updatedAt = DateTime.now();
    await _localDataSource.saveWorkout(workout);
  }
}

