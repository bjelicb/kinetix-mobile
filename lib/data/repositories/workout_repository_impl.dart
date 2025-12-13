import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart' as domain;
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
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[WorkoutRepositoryImpl] getWorkouts() START');
    debugPrint('[WorkoutRepositoryImpl] → Platform: ${kIsWeb ? "Web" : "Mobile"}');

    // Web platform: load from API
    if (kIsWeb && _remoteDataSource != null) {
      debugPrint('[WorkoutRepositoryImpl] → Web platform - loading from API');
      try {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        debugPrint('[WorkoutRepositoryImpl] → Calling getWeekWorkouts API with date: $dateStr');

        final response = await _remoteDataSource.getWeekWorkouts(dateStr);
        debugPrint('[WorkoutRepositoryImpl] → API response type: ${response.runtimeType}');

        // Parse response - handle both direct array and wrapped format
        List<dynamic> workoutLogsData = [];
        if (response is List) {
          // Direct array response
          workoutLogsData = response;
        } else if (response is Map<String, dynamic>) {
          // Wrapped response: {data: [...]}
          final data = response['data'];
          if (data is List) {
            workoutLogsData = data;
          } else {
            debugPrint(
              '[WorkoutRepositoryImpl] → Warning: response.data is not a List, type: ${data?.runtimeType ?? 'null'}',
            );
            debugPrint('[WorkoutRepositoryImpl] → Response keys: ${response.keys.join(", ")}');
            return [];
          }
        } else {
          debugPrint('[WorkoutRepositoryImpl] → Warning: Unexpected response type: ${response.runtimeType}');
          return [];
        }

        debugPrint('[WorkoutRepositoryImpl] → Parsed ${workoutLogsData.length} workout logs from API');

        final workouts = <Workout>[];
        for (var i = 0; i < workoutLogsData.length; i++) {
          try {
            final logData = workoutLogsData[i] as Map<String, dynamic>;
            debugPrint('[WorkoutRepositoryImpl] → Converting workout log ${i + 1}/${workoutLogsData.length}');

            // Convert WorkoutLog to Workout entity
            final workout = _workoutLogFromServerData(logData);
            workouts.add(workout);

            debugPrint(
              '[WorkoutRepositoryImpl] ✓ Converted: ${workout.name} (${workout.scheduledDate.toIso8601String()}), isCompleted: ${workout.isCompleted}, isMissed: ${workout.isMissed}, isRestDay: ${workout.isRestDay}',
            );
          } catch (e, stackTrace) {
            debugPrint('[WorkoutRepositoryImpl] ✗ Failed to convert workout log ${i + 1}: $e');
            debugPrint('[WorkoutRepositoryImpl] → Stack trace: $stackTrace');
          }
        }

        debugPrint('[WorkoutRepositoryImpl] → Total converted: ${workouts.length}/${workoutLogsData.length}');
        debugPrint('═══════════════════════════════════════════════════════════');
        return workouts;
      } catch (e, stackTrace) {
        debugPrint('[WorkoutRepositoryImpl] ✗ Error loading workouts from API: $e');
        debugPrint('[WorkoutRepositoryImpl] → Stack trace: $stackTrace');
        return [];
      }
    }

    // Mobile platform: load from Isar
    debugPrint('[WorkoutRepositoryImpl] → Mobile platform - loading from Isar');
    try {
      final List<WorkoutCollection> collections = await _localDataSource.getWorkouts();
      debugPrint('[WorkoutRepositoryImpl] → Found ${collections.length} workout logs in Isar');

      final workouts = <Workout>[];
      for (final WorkoutCollection collection in collections) {
        try {
          final List<ExerciseCollection> exercises = await _localDataSource.getExercisesForWorkout(collection.id);
          final exerciseEntities = exercises.map((e) => ExerciseMapper.toEntity(e)).toList();
          workouts.add(WorkoutMapper.toEntity(collection, exerciseEntities));
        } catch (e) {
          workouts.add(WorkoutMapper.toEntity(collection, []));
        }
      }

      debugPrint('[WorkoutRepositoryImpl] → Converted ${workouts.length} workout logs');
      debugPrint('═══════════════════════════════════════════════════════════');
      return workouts;
    } catch (e) {
      debugPrint('[WorkoutRepositoryImpl] ✗ Error loading workouts from Isar: $e');
      return [];
    }
  }

  // Helper method to convert server WorkoutLog to Workout entity
  // Backend now provides: workoutName, isRestDay, planExercises - ready to use
  Workout _workoutLogFromServerData(Map<String, dynamic> logData) {
    final serverId = logData['_id']?.toString() ?? '';
    final workoutDate = DateTime.parse(logData['workoutDate'] as String);
    final isCompleted = logData['isCompleted'] as bool? ?? false;
    final isMissed = logData['isMissed'] as bool? ?? false;

    // Use workoutName from backend (already determined from plan workout day)
    final workoutName =
        logData['workoutName'] as String? ??
        (logData['weeklyPlanId'] is Map ? (logData['weeklyPlanId'] as Map)['name'] as String? : null) ??
        'Workout';

    // Use isRestDay from backend (already determined from plan)
    final isRestDay = logData['isRestDay'] as bool? ?? false;

    // Convert exercises from planExercises (backend provides complete plan exercise data)
    final exercises = <domain.Exercise>[];
    if (logData['planExercises'] != null) {
      final planExercises = logData['planExercises'] as List<dynamic>;
      for (final exData in planExercises) {
        exercises.add(
          domain.Exercise(
            id: '',
            name: exData['name'] as String? ?? 'Exercise',
            targetMuscle: 'Unknown',
            sets: [], // Sets will be populated from completedExercises if workout is started/completed
            restSeconds: exData['restSeconds'] as int?,
            notes: exData['notes'] as String?,
            planSets: exData['sets'] as int?,
            planReps: exData['reps'],
          ),
        );
      }
    } else if (logData['completedExercises'] != null) {
      // Fallback: use completedExercises if planExercises not available
      final completedExercises = logData['completedExercises'] as List<dynamic>;
      for (final exData in completedExercises) {
        exercises.add(
          domain.Exercise(
            id: '',
            name: exData['exerciseName'] as String? ?? 'Exercise',
            targetMuscle: 'Unknown',
            sets: [],
          ),
        );
      }
    }

    return Workout(
      id: serverId,
      serverId: serverId,
      name: workoutName,
      scheduledDate: workoutDate,
      isCompleted: isCompleted,
      isMissed: isMissed,
      isRestDay: isRestDay,
      exercises: exercises,
      isDirty: false,
      updatedAt: DateTime.parse(logData['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
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
