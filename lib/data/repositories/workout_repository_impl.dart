import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:uuid/uuid.dart';
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
          workoutLogsData = response;
        } else if (response is Map<String, dynamic>) {
          final data = response['data'];
          if (data is List) {
            workoutLogsData = data;
          } else {
            debugPrint('[WorkoutRepositoryImpl] → Warning: response.data is not a List');
            return [];
          }
        } else {
          debugPrint('[WorkoutRepositoryImpl] → Warning: Unexpected response type');
          return [];
        }

        debugPrint('[WorkoutRepositoryImpl] → Parsed ${workoutLogsData.length} workout logs from API');

        final workouts = <Workout>[];
        for (var i = 0; i < workoutLogsData.length; i++) {
          try {
            final logData = workoutLogsData[i] as Map<String, dynamic>;
            final workout = _workoutLogFromServerData(logData);
            workouts.add(workout);
            debugPrint('[WorkoutRepositoryImpl] ✓ Converted: ${workout.name}, exercises: ${workout.exercises.length}');
          } catch (e) {
            debugPrint('[WorkoutRepositoryImpl] ✗ Failed to convert workout log ${i + 1}: $e');
          }
        }

        debugPrint('[WorkoutRepositoryImpl] → Total converted: ${workouts.length}/${workoutLogsData.length}');
        debugPrint('═══════════════════════════════════════════════════════════');
        return workouts;
      } catch (e) {
        debugPrint('[WorkoutRepositoryImpl] ✗ Error loading workouts from API: $e');
        return [];
      }
    }

    // Mobile platform: load from Isar, fetch from API if empty
    debugPrint('[WorkoutRepositoryImpl] → Mobile platform - loading from Isar');
    try {
      List<WorkoutCollection> collections = await _localDataSource.getWorkouts();
      debugPrint('[WorkoutRepositoryImpl] → Found ${collections.length} workout logs in Isar');

      // If Isar is empty and we have remote data source, fetch from API
      if (collections.isEmpty && _remoteDataSource != null) {
        debugPrint('[WorkoutRepositoryImpl] → Isar empty, fetching from API...');
        try {
          final today = DateTime.now();
          final dateStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final response = await _remoteDataSource.getWeekWorkouts(dateStr);
          
          List<dynamic> workoutLogsData = [];
          if (response is List) {
            workoutLogsData = response;
          } else if (response is Map<String, dynamic>) {
            final data = response['data'];
            if (data is List) {
              workoutLogsData = data;
            }
          }
          
          debugPrint('[WorkoutRepositoryImpl] → API returned ${workoutLogsData.length} workout logs');
          
          // Save to Isar (workouts AND exercises)
          int savedCount = 0;
          int exerciseCount = 0;
          for (final logData in workoutLogsData) {
            try {
              final data = logData as Map<String, dynamic>;
              final collection = _workoutLogToCollection(data);
              await _localDataSource.saveWorkout(collection);
              savedCount++;
              debugPrint('[WorkoutRepositoryImpl] → Saved workout: ${collection.name} (ID: ${collection.id})');
              
              // After saveWorkout, collection.id should have the Isar-assigned ID
              if (collection.id > 0) {
                final exerciseCollections = _extractExercisesFromLogData(data);
                if (exerciseCollections.isNotEmpty) {
                  await _localDataSource.saveExercisesForWorkout(collection.id, exerciseCollections);
                  exerciseCount += exerciseCollections.length;
                  debugPrint('[WorkoutRepositoryImpl] → Saved ${exerciseCollections.length} exercises for workout ${collection.name}');
                }
              }
            } catch (e) {
              debugPrint('[WorkoutRepositoryImpl] ✗ Failed to save workout: $e');
            }
          }
          
          debugPrint('[WorkoutRepositoryImpl] ✓ Saved $savedCount workouts with $exerciseCount total exercises');
          collections = await _localDataSource.getWorkouts();
          debugPrint('[WorkoutRepositoryImpl] → After API sync, found ${collections.length} workout logs in Isar');
        } catch (e) {
          debugPrint('[WorkoutRepositoryImpl] ✗ API fetch failed: $e');
        }
      }

      final workouts = <Workout>[];
      for (final WorkoutCollection collection in collections) {
        try {
          final List<ExerciseCollection> exercises = await _localDataSource.getExercisesForWorkout(collection.id);
          debugPrint('[WorkoutRepositoryImpl] → Workout "${collection.name}" has ${exercises.length} exercises in Isar');
          final exerciseEntities = exercises.map((e) => ExerciseMapper.toEntity(e)).toList();
          workouts.add(WorkoutMapper.toEntity(collection, exerciseEntities));
        } catch (e) {
          debugPrint('[WorkoutRepositoryImpl] → Error loading exercises for workout ${collection.id}: $e');
          workouts.add(WorkoutMapper.toEntity(collection, []));
        }
      }

      debugPrint('[WorkoutRepositoryImpl] → Converted ${workouts.length} workout logs with exercises');
      debugPrint('═══════════════════════════════════════════════════════════');
      return workouts;
    } catch (e) {
      debugPrint('[WorkoutRepositoryImpl] ✗ Error loading workouts from Isar: $e');
      return [];
    }
  }
  
  /// Convert server workout log data to WorkoutCollection for Isar storage
  WorkoutCollection _workoutLogToCollection(Map<String, dynamic> logData) {
    final collection = WorkoutCollection();
    collection.serverId = logData['_id']?.toString() ?? '';
    collection.name = logData['workoutName'] as String? ?? 
        (logData['weeklyPlanId'] is Map ? (logData['weeklyPlanId'] as Map)['name'] as String? : null) ?? 
        'Workout';
    collection.scheduledDate = DateTime.parse(logData['workoutDate'] as String);
    collection.isCompleted = logData['isCompleted'] as bool? ?? false;
    collection.isMissed = logData['isMissed'] as bool? ?? false;
    collection.isRestDay = logData['isRestDay'] as bool? ?? false;
    collection.isDirty = false;
    collection.updatedAt = logData['updatedAt'] != null 
        ? DateTime.parse(logData['updatedAt'] as String) 
        : DateTime.now();
    return collection;
  }

  /// Extract exercises from server workout log data for Isar storage
  List<ExerciseCollection> _extractExercisesFromLogData(Map<String, dynamic> logData) {
    final exercises = <ExerciseCollection>[];
    
    // Try planExercises first (from plan template)
    if (logData['planExercises'] != null && logData['planExercises'] is List) {
      final planExercises = logData['planExercises'] as List<dynamic>;
      for (final exData in planExercises) {
        if (exData is Map<String, dynamic>) {
          final exercise = ExerciseCollection();
          exercise.name = exData['name'] as String? ?? 'Exercise';
          exercise.targetMuscle = exData['targetMuscle'] as String? ?? '';
          exercise.sets = []; // Plan exercises don't have completed sets yet
          // Store plan metadata for display
          exercise.planSets = exData['sets'] as int?;
          exercise.planReps = exData['reps']?.toString();
          exercise.restSeconds = exData['restSeconds'] as int?;
          exercise.notes = exData['notes'] as String?;
          exercise.videoUrl = exData['videoUrl'] as String?;
          exercises.add(exercise);
        }
      }
    } 
    // Fallback to completedExercises (for completed workouts)
    else if (logData['completedExercises'] != null && logData['completedExercises'] is List) {
      final completedExercises = logData['completedExercises'] as List<dynamic>;
      for (final exData in completedExercises) {
        if (exData is Map<String, dynamic>) {
          final exercise = ExerciseCollection();
          exercise.name = exData['exerciseName'] as String? ?? 'Exercise';
          exercise.targetMuscle = exData['targetMuscle'] as String? ?? '';
          exercise.sets = [];
          // completedExercises have different structure - actualSets, actualReps, weightUsed
          exercise.planSets = exData['actualSets'] as int?;
          exercise.notes = exData['notes'] as String?;
          exercises.add(exercise);
        }
      }
    }
    
    return exercises;
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
        final planSets = exData['sets'] as int?;
        final planReps = exData['reps'];
        
        // Generate sets based on planSets and planReps (similar to ExerciseMapper logic)
        List<domain.WorkoutSet> sets = [];
        if (planSets != null && planSets > 0) {
          // Parse planReps to get default reps value
          int defaultReps = 0;
          if (planReps != null) {
            if (planReps is int) {
              defaultReps = planReps;
            } else if (planReps is String) {
              // Parse string like "10" or "10-12" - take first number
              final match = RegExp(r'(\d+)').firstMatch(planReps);
              if (match != null) {
                defaultReps = int.tryParse(match.group(1) ?? '0') ?? 0;
              }
            }
          }
          
          // Generate empty sets based on planSets
          sets = List.generate(planSets, (index) {
            return domain.WorkoutSet(
              id: const Uuid().v4(), // Generate unique UUID for each set
              weight: 0.0,
              reps: defaultReps,
              rpe: null,
              isCompleted: false,
            );
          });
        }
        
        exercises.add(
          domain.Exercise(
            id: '',
            name: exData['name'] as String? ?? 'Exercise',
            targetMuscle: exData['targetMuscle'] as String? ?? '',
            sets: sets,
            restSeconds: exData['restSeconds'] as int?,
            notes: exData['notes'] as String?,
            planSets: planSets,
            planReps: planReps,
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
            targetMuscle: exData['targetMuscle'] as String? ?? '',
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
    // On web platform, workouts are loaded from API and stored in memory only
    // We can't update them in Isar (which doesn't exist on web)
    // For now, just return the updated workout - it will be in memory state
    // TODO: In the future, we might want to sync updates to the backend API
    if (kIsWeb) {
      debugPrint('[WorkoutRepositoryImpl] updateWorkout on web - returning workout (no local storage)');
      return workout;
    }
    
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
