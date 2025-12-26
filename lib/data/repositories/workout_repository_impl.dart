import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  // ignore: unused_field
  final FlutterSecureStorage _storage;

  // Cache for COUNT COMPARISON to avoid checking on every getWorkouts() call
  // Use instance-level cache instead of static to avoid issues with multiple instances (web scenario)
  DateTime? _lastCountCheck;
  static const Duration _countCheckInterval = Duration(minutes: 5);

  // Lock to prevent race condition between COUNT COMPARISON and other operations
  bool _isCountComparisonRunning = false;

  WorkoutRepositoryImpl(this._localDataSource, this._remoteDataSource, this._storage);

  @override
  Future<List<Workout>> getWorkouts() async {
    // Web platform: load from API
    if (kIsWeb && _remoteDataSource != null) {
      try {
        final response = await _remoteDataSource.getAllWorkoutLogs();

        // Parse response - handle both direct array and wrapped format
        List<dynamic> workoutLogsData = [];
        if (response is List) {
          workoutLogsData = response;
        } else if (response is Map<String, dynamic>) {
          final data = response['data'];
          if (data is List) {
            workoutLogsData = data;
          } else {
            debugPrint('[WorkoutRepositoryImpl] ⚠️ Warning: response.data is not a List');
            return [];
          }
        } else {
          debugPrint('[WorkoutRepositoryImpl] ⚠️ Warning: Unexpected response type');
          return [];
        }

        final workouts = <Workout>[];
        for (var i = 0; i < workoutLogsData.length; i++) {
          try {
            final logData = workoutLogsData[i] as Map<String, dynamic>;
            final workout = _workoutLogFromServerData(logData);
            workouts.add(workout);
          } catch (e) {
            debugPrint('[WorkoutRepositoryImpl] ✗ Failed to convert workout log ${i + 1}: $e');
          }
        }

        return workouts;
      } catch (e) {
        debugPrint('[WorkoutRepositoryImpl] ✗ Error loading workouts from API: $e');
        return [];
      }
    }

    // Mobile platform: load from Isar, fetch from API if empty or if data is corrupted
    try {
      List<WorkoutCollection> collections = await _localDataSource.getWorkouts();

      // Check if Isar has "bad" data (corrupted workout names or missing exercises)
      bool needsRefresh = false;
      if (collections.isNotEmpty) {
        for (final collection in collections) {
          // Check if workout name is corrupted
          if (collection.name == 'Workout' || collection.name.isEmpty) {
            debugPrint(
              '[WorkoutRepositoryImpl] ⚠️ Found corrupted workout name: "${collection.name}" (ID: ${collection.id})',
            );
            needsRefresh = true;
            break;
          }
          // Check if exercises are missing
          try {
            final exercises = await _localDataSource.getExercisesForWorkout(collection.id);
            if (exercises.isEmpty && !collection.isRestDay) {
              debugPrint(
                '[WorkoutRepositoryImpl] ⚠️ Found workout without exercises: "${collection.name}" (ID: ${collection.id}, isRestDay: ${collection.isRestDay})',
              );
              needsRefresh = true;
              break;
            }
            // Check if completed workout has sets (completed workouts should have sets with weight/reps)
            if (collection.isCompleted && !collection.isRestDay && exercises.isNotEmpty) {
              bool hasSets = false;
              for (final exercise in exercises) {
                if (exercise.sets.isNotEmpty) {
                  hasSets = true;
                  break;
                }
              }
              if (!hasSets) {
                debugPrint(
                  '[WorkoutRepositoryImpl] ⚠️ Found completed workout without sets: "${collection.name}" (ID: ${collection.id}) - needs refresh',
                );
                needsRefresh = true;
                break;
              }
            }
          } catch (e) {
            debugPrint('[WorkoutRepositoryImpl] ⚠️ Error checking exercises for workout ${collection.id}: $e');
            needsRefresh = true;
            break;
          }
        }
        if (needsRefresh) {
          debugPrint('[WorkoutRepositoryImpl] ⚠️ Corrupted data detected in Isar - forcing API refresh');
        }
      }

      // Check if server has more logs than Isar (CRITICAL for missing logs)
      // OPTIMIZED: Store server logs data to reuse for sync (avoid duplicate API call)
      List<dynamic>? serverLogsDataForSync;

      // COUNT COMPARISON: Only check if enough time has passed since last check
      // Also check if another COUNT COMPARISON is already running (race condition prevention)
      final now = DateTime.now();
      final shouldCheckCount =
          !_isCountComparisonRunning &&
          (collections.isNotEmpty && !needsRefresh) &&
          (_lastCountCheck == null || now.difference(_lastCountCheck!) > _countCheckInterval) &&
          _remoteDataSource != null;

      if (shouldCheckCount) {
        _isCountComparisonRunning = true; // Set lock
        _lastCountCheck = now; // Update last check time

        try {
          final response = await _remoteDataSource.getAllWorkoutLogs();
          List<dynamic> serverLogsData = [];
          if (response is List) {
            serverLogsData = response;
          } else if (response is Map<String, dynamic>) {
            final data = response['data'];
            if (data is List) {
              serverLogsData = data;
            }
          }

          // If server has more logs, force sync and reuse the data we already fetched
          if (serverLogsData.length > collections.length) {
            debugPrint(
              '[WorkoutRepositoryImpl] ⚠️ Server has MORE logs than Isar (${serverLogsData.length} vs ${collections.length}) - forcing sync',
            );
            needsRefresh = true;
            serverLogsDataForSync = serverLogsData; // OPTIMIZATION: Reuse data instead of fetching again
          } else if (serverLogsData.length < collections.length) {
            debugPrint(
              '[WorkoutRepositoryImpl] ⚠️ WARNING: Isar has MORE logs than server (${collections.length} vs ${serverLogsData.length}) - data inconsistency',
            );
          }
        } catch (e) {
          debugPrint('[WorkoutRepositoryImpl] ⚠️ Failed to check server count: $e');
          // Continue with existing logic if check fails
        } finally {
          _isCountComparisonRunning = false; // Release lock
        }
      }

      // ALWAYS sync with backend to ensure data consistency (backend is source of truth)
      // This ensures that workout names, exercises, and sets are always up-to-date
      if (_remoteDataSource != null) {
        debugPrint('[WorkoutRepositoryImpl] → Syncing with backend (backend is source of truth)...');
        try {
          // OPTIMIZATION: Use already fetched data if available, otherwise fetch from API
          List<dynamic> workoutLogsData = serverLogsDataForSync ?? [];

          if (workoutLogsData.isEmpty) {
            // Only fetch if we don't have the data from COUNT COMPARISON
            final response = await _remoteDataSource.getAllWorkoutLogs();
            if (response is List) {
              workoutLogsData = response;
            } else if (response is Map<String, dynamic>) {
              final data = response['data'];
              if (data is List) {
                workoutLogsData = data;
              }
            }
          }

          debugPrint('[WorkoutRepositoryImpl] → Syncing ${workoutLogsData.length} workout logs from backend...');

          // Save to Isar (workouts AND exercises)
          int savedCount = 0;
          int exerciseCount = 0;
          for (final logData in workoutLogsData) {
            try {
              final data = logData as Map<String, dynamic>;
              final collection = _workoutLogToCollection(data);
              await _localDataSource.saveWorkout(collection);
              savedCount++;

              // After saveWorkout, collection.id should have the Isar-assigned ID
              if (collection.id > 0) {
                final exerciseCollections = _extractExercisesFromLogData(data);
                if (exerciseCollections.isNotEmpty) {
                  await _localDataSource.saveExercisesForWorkout(collection.id, exerciseCollections);
                  exerciseCount += exerciseCollections.length;
                }
              }
            } catch (e) {
              debugPrint('[WorkoutRepositoryImpl] ✗ Failed to save workout: $e');
            }
          }

          debugPrint('[WorkoutRepositoryImpl] ✓ Saved $savedCount workouts with $exerciseCount total exercises');
          collections = await _localDataSource.getWorkouts();
        } catch (e) {
          debugPrint('[WorkoutRepositoryImpl] ✗ API fetch failed: $e');
        }
      }

      // Filter duplicates by date + planId before processing
      // Keep only the most recent workout for each date+planId combination
      // This prevents showing multiple workouts for the same day/plan (e.g., "Rest Day" and "Leg Day" on same date)
      // IMPORTANT: For the same date and plan, there should be only ONE workout log (backend enforces this)
      final uniqueCollections = <String, WorkoutCollection>{};
      final duplicateIds = <int>[];

      for (final collection in collections) {
        // Create unique key: date + planId (YYYY-MM-DD)
        // NOT including dayOfWeek because backend should only have ONE workout per date+plan
        final dateKey =
            '${collection.scheduledDate.year}-${collection.scheduledDate.month.toString().padLeft(2, '0')}-${collection.scheduledDate.day.toString().padLeft(2, '0')}';
        final planId = collection.planId ?? 'no-plan';
        // Use date + planId as unique key (backend enforces one workout per date+plan)
        final uniqueKey = '${dateKey}_$planId';

        if (uniqueCollections.containsKey(uniqueKey)) {
          // Duplicate found - prioritize workout with serverId (from backend) over local-only workouts
          final existing = uniqueCollections[uniqueKey]!;

          // Priority 1: Workout with serverId (from backend) is always preferred
          final collectionHasServerId = collection.serverId.isNotEmpty;
          final existingHasServerId = existing.serverId.isNotEmpty;

          if (collectionHasServerId && !existingHasServerId) {
            // New workout has serverId, existing doesn't - keep new one
            duplicateIds.add(existing.id);
            uniqueCollections[uniqueKey] = collection;
          } else if (!collectionHasServerId && existingHasServerId) {
            // Existing workout has serverId, new doesn't - keep existing one
            duplicateIds.add(collection.id);
          } else {
            // Both have serverId or both don't - use updatedAt as tiebreaker
            if (collection.updatedAt.isAfter(existing.updatedAt)) {
              duplicateIds.add(existing.id);
              uniqueCollections[uniqueKey] = collection;
            } else {
              duplicateIds.add(collection.id);
            }
          }
        } else {
          uniqueCollections[uniqueKey] = collection;
        }
      }

      if (duplicateIds.isNotEmpty) {
        debugPrint('[WorkoutRepositoryImpl] ⚠️ Found ${duplicateIds.length} duplicate workouts - removing duplicates');
        // Delete duplicates from database
        for (final id in duplicateIds) {
          try {
            await _localDataSource.deleteWorkout(id);
          } catch (e) {
            debugPrint('[WorkoutRepositoryImpl] ⚠️ Failed to delete duplicate workout $id: $e');
          }
        }
      }

      final workouts = <Workout>[];
      for (final WorkoutCollection collection in uniqueCollections.values) {
        try {
          final List<ExerciseCollection> exercises = await _localDataSource.getExercisesForWorkout(collection.id);

          // Check for duplicates before mapping
          final exerciseNames = exercises.map((e) => e.name).toList();
          final uniqueNames = exerciseNames.toSet();
          if (exerciseNames.length != uniqueNames.length) {
            debugPrint(
              '[WorkoutRepositoryImpl] ⚠️ WARNING: Found ${exerciseNames.length - uniqueNames.length} duplicate exercises in workout "${collection.name}"',
            );
            // Remove duplicates - keep first occurrence of each name
            final seen = <String>{};
            final uniqueExercises = exercises.where((e) {
              if (seen.contains(e.name)) {
                return false;
              }
              seen.add(e.name);
              return true;
            }).toList();
            final exerciseEntities = uniqueExercises.map((e) => ExerciseMapper.toEntity(e)).toList();
            workouts.add(WorkoutMapper.toEntity(collection, exerciseEntities));
          } else {
            final exerciseEntities = exercises.map((e) => ExerciseMapper.toEntity(e)).toList();
            workouts.add(WorkoutMapper.toEntity(collection, exerciseEntities));
          }
        } catch (e) {
          debugPrint('[WorkoutRepositoryImpl] ⚠️ Error loading exercises for workout ${collection.id}: $e');
          workouts.add(WorkoutMapper.toEntity(collection, []));
        }
      }
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

    // Extract planId from weeklyPlanId
    if (logData['weeklyPlanId'] != null) {
      if (logData['weeklyPlanId'] is String) {
        collection.planId = logData['weeklyPlanId'] as String;
      } else if (logData['weeklyPlanId'] is Map) {
        final weeklyPlanIdMap = logData['weeklyPlanId'] as Map<String, dynamic>;
        collection.planId = weeklyPlanIdMap['_id']?.toString();
      }
    }

    // Extract dayOfWeek (Plan day index 1-7, pozicija u planu)
    collection.dayOfWeek = logData['dayOfWeek'] as int?;

    if (collection.dayOfWeek == null) {
      debugPrint(
        '[WorkoutRepositoryImpl] ⚠️ WARNING: dayOfWeek is null in logData - workout may not be able to find plan workout',
      );
    }

    // Extract workout name - try multiple sources
    String? workoutName;

    // 1. Try workoutName directly (backend should provide this)
    workoutName = logData['workoutName'] as String?;

    // 2. Try to extract from weeklyPlanId.workouts array using dayOfWeek from log
    // dayOfWeek in log is the plan day index (1-7), NOT the day of the week
    if ((workoutName == null || workoutName == 'Workout') && logData['weeklyPlanId'] is Map) {
      final weeklyPlanId = logData['weeklyPlanId'] as Map<String, dynamic>;
      final logDayOfWeek = logData['dayOfWeek'] as int?; // Plan day index (1-7)

      // Try to get workout day from workouts array
      if (logDayOfWeek != null && weeklyPlanId['workouts'] is List) {
        final workouts = weeklyPlanId['workouts'] as List<dynamic>;

        // Find matching workout day in plan using log.dayOfWeek (plan day index)
        for (final workoutDay in workouts) {
          if (workoutDay is Map<String, dynamic>) {
            final workoutDayOfWeek = workoutDay['dayOfWeek'] as int?;
            if (workoutDayOfWeek == logDayOfWeek) {
              workoutName = workoutDay['name'] as String?;
              break;
            }
          }
        }
      }
    }

    // 3. Try planId populated object
    if ((workoutName == null || workoutName == 'Workout') && logData['planId'] is Map) {
      final planId = logData['planId'] as Map<String, dynamic>;
      workoutName = planId['name'] as String?;
    }

    // 4. Fallback to 'Workout'
    collection.name = workoutName ?? 'Workout';

    if (collection.name == 'Workout') {
      debugPrint('[WorkoutRepositoryImpl] ⚠️ WARNING: Using fallback name "Workout" - workoutName extraction failed');
    }
    collection.scheduledDate = DateTime.parse(logData['workoutDate'] as String);
    collection.isCompleted = logData['isCompleted'] as bool? ?? false;
    collection.isMissed = logData['isMissed'] as bool? ?? false;
    collection.isRestDay = logData['isRestDay'] as bool? ?? false;
    collection.isDirty = false;
    collection.isSyncing = false; // NOVO: Default to false
    collection.updatedAt = logData['updatedAt'] != null
        ? DateTime.parse(logData['updatedAt'] as String)
        : DateTime.now();
    return collection;
  }

  /// Extract exercises from server workout log data for Isar storage
  List<ExerciseCollection> _extractExercisesFromLogData(Map<String, dynamic> logData) {
    final exercises = <ExerciseCollection>[];

    // Try planExercises first (from plan template) - check if it exists and is not empty
    if (logData['planExercises'] != null &&
        logData['planExercises'] is List &&
        (logData['planExercises'] as List).isNotEmpty) {
      final planExercises = logData['planExercises'] as List<dynamic>;
      final isCompleted = logData['isCompleted'] as bool? ?? false;

      // Create a map of completedExercises by exerciseName for quick lookup
      final completedExercisesMap = <String, Map<String, dynamic>>{};
      if (isCompleted && logData['completedExercises'] != null && logData['completedExercises'] is List) {
        final completedExercises = logData['completedExercises'] as List<dynamic>;
        for (final completedEx in completedExercises) {
          if (completedEx is Map<String, dynamic>) {
            final exerciseName = completedEx['exerciseName'] as String?;
            if (exerciseName != null) {
              completedExercisesMap[exerciseName] = completedEx;
            }
          }
        }
      }

      for (final exData in planExercises) {
        if (exData is Map<String, dynamic>) {
          final exercise = ExerciseCollection();
          final exerciseName = exData['name'] as String? ?? 'Exercise';
          exercise.name = exerciseName;
          exercise.targetMuscle = exData['targetMuscle'] as String? ?? '';

          // Store plan metadata for display
          exercise.planSets = exData['sets'] as int?;
          exercise.planReps = exData['reps']?.toString();
          exercise.restSeconds = exData['restSeconds'] as int?;
          exercise.notes = exData['notes'] as String?;
          exercise.videoUrl = exData['videoUrl'] as String?;

          // If workout is completed, merge with completedExercises to get actual sets/reps/weight
          if (isCompleted) {
            final completedEx = completedExercisesMap[exerciseName];
            if (completedEx != null) {
              final actualSets = completedEx['actualSets'] as int? ?? exercise.planSets ?? 0;
              final actualReps = completedEx['actualReps'] as List<dynamic>?;
              final weightUsed = (completedEx['weightUsed'] as num?)?.toDouble() ?? 0.0;

              // Generate WorkoutSet objects from completedExercises data
              final sets = <WorkoutSet>[];
              for (int i = 0; i < actualSets; i++) {
                final reps = actualReps != null && i < actualReps.length
                    ? (actualReps[i] as num?)?.toInt() ?? 0
                    : (exercise.planReps != null ? int.tryParse(exercise.planReps!.split('-')[0]) ?? 0 : 0);

                final workoutSet = WorkoutSet();
                workoutSet.id = const Uuid().v4();
                workoutSet.weight = weightUsed;
                workoutSet.reps = reps;
                workoutSet.rpe = null; // RPE not stored in completedExercises
                workoutSet.isCompleted = true; // Mark as completed since we have completed data
                sets.add(workoutSet);
              }

              exercise.sets = sets;
            } else {
              // No completed data - use empty sets
              exercise.sets = [];
            }
          } else {
            // Workout not completed - use empty sets
            exercise.sets = [];
          }

          exercises.add(exercise);
        }
      }
    }
    // Fallback: Try to extract from weeklyPlanId.workouts[].exercises using dayOfWeek
    else if (logData['weeklyPlanId'] is Map) {
      final weeklyPlanId = logData['weeklyPlanId'] as Map<String, dynamic>;
      final logDayOfWeek = logData['dayOfWeek'] as int?;

      if (logDayOfWeek != null && weeklyPlanId['workouts'] is List) {
        final workouts = weeklyPlanId['workouts'] as List<dynamic>;

        // Find matching workout day in plan using log.dayOfWeek (plan day index)
        Map<String, dynamic>? planWorkout;
        for (final workoutDay in workouts) {
          if (workoutDay is Map<String, dynamic>) {
            final workoutDayOfWeek = workoutDay['dayOfWeek'] as int?;
            if (workoutDayOfWeek == logDayOfWeek) {
              planWorkout = workoutDay;
              break;
            }
          }
        }

        if (planWorkout != null && planWorkout['exercises'] is List) {
          final planExercises = planWorkout['exercises'] as List<dynamic>;
          for (final exData in planExercises) {
            if (exData is Map<String, dynamic>) {
              final exercise = ExerciseCollection();
              exercise.name = exData['name'] as String? ?? 'Exercise';
              exercise.targetMuscle = exData['targetMuscle'] as String? ?? '';
              exercise.sets = [];
              exercise.planSets = exData['sets'] as int?;
              exercise.planReps = exData['reps']?.toString();
              exercise.restSeconds = exData['restSeconds'] as int?;
              exercise.notes = exData['notes'] as String?;
              exercise.videoUrl = exData['videoUrl'] as String?;
              exercises.add(exercise);
            }
          }
        }
      }
    }
    // Last resort fallback: completedExercises (for completed workouts)
    if (exercises.isEmpty && logData['completedExercises'] != null && logData['completedExercises'] is List) {
      final completedExercises = logData['completedExercises'] as List<dynamic>;
      for (final exData in completedExercises) {
        if (exData is Map<String, dynamic>) {
          final exercise = ExerciseCollection();
          exercise.name = exData['exerciseName'] as String? ?? 'Exercise';
          exercise.targetMuscle = exData['targetMuscle'] as String? ?? '';
          exercise.sets = [];
          // completedExercises have different structure - actualSets, actualReps, weightUsed
          exercise.planSets = exData['actualSets'] as int? ?? exData['planSets'] as int?;
          exercise.planReps = (exData['reps'] ?? exData['planReps'])?.toString();
          exercise.restSeconds = exData['restSeconds'] as int?;
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

    // Extract planId from weeklyPlanId
    String? planId;
    if (logData['weeklyPlanId'] != null) {
      if (logData['weeklyPlanId'] is String) {
        planId = logData['weeklyPlanId'] as String;
      } else if (logData['weeklyPlanId'] is Map) {
        final weeklyPlanIdMap = logData['weeklyPlanId'] as Map<String, dynamic>;
        planId = weeklyPlanIdMap['_id']?.toString();
      }
    }

    // Extract dayOfWeek from logData (Plan day index 1-7)
    // dayOfWeek je pozicija u planu (1-7), ne calendar day of week
    // Backend već šalje ovo u WorkoutLog podacima - samo treba da ga čuvamo
    final dayOfWeek = logData['dayOfWeek'] as int?;

    if (dayOfWeek == null) {
      debugPrint(
        '[WorkoutRepositoryImpl] ⚠️ WARNING: dayOfWeek is null in logData - workout may not be able to find plan workout',
      );
    }

    // Use workoutName from backend (backend now provides this via getAllWorkoutLogsEnriched)
    // Priority: 1) workoutName from backend, 2) Extract from weeklyPlanId.workouts, 3) Fallback to 'Workout'
    String? workoutName;

    // 1. PRIORITY: Try workoutName directly from backend (should now be present)
    workoutName = logData['workoutName'] as String?;

    // 2. FALLBACK: Try to extract from weeklyPlanId.workouts array using dayOfWeek from log
    // (Only if workoutName is missing or 'Workout' - this should rarely happen if backend is correct)
    if ((workoutName == null || workoutName == 'Workout') && logData['weeklyPlanId'] is Map) {
      final weeklyPlanId = logData['weeklyPlanId'] as Map<String, dynamic>;
      final logDayOfWeek = logData['dayOfWeek'] as int?; // Plan day index (1-7)

      // Try to get workout day from workouts array (if present in response)
      if (logDayOfWeek != null && weeklyPlanId['workouts'] is List) {
        final workouts = weeklyPlanId['workouts'] as List<dynamic>;

        // Find matching workout day in plan using log.dayOfWeek (plan day index)
        for (final workoutDay in workouts) {
          if (workoutDay is Map<String, dynamic>) {
            final workoutDayOfWeek = workoutDay['dayOfWeek'] as int?;
            if (workoutDayOfWeek == logDayOfWeek) {
              workoutName = workoutDay['name'] as String?;
              break;
            }
          }
        }
      }
    }

    // 3. FINAL FALLBACK: Use 'Workout' (NEVER use plan name as fallback)
    workoutName = workoutName ?? 'Workout';

    // Use isRestDay from backend (already determined from plan)
    final isRestDay = logData['isRestDay'] as bool? ?? false;

    // Convert exercises - PRIORITY: 1) planExercises from backend, 2) weeklyPlanId.workouts, 3) completedExercises
    final exercises = <domain.Exercise>[];

    // 1. PRIORITY: Check if planExercises exists and is not empty (backend now provides this via getAllWorkoutLogsEnriched)
    if (logData['planExercises'] != null &&
        logData['planExercises'] is List &&
        (logData['planExercises'] as List).isNotEmpty) {
      final planExercises = logData['planExercises'] as List<dynamic>;
      final completedExercises = logData['completedExercises'] as List<dynamic>? ?? [];

      // Create a map of completedExercises by exerciseName for quick lookup
      final completedExercisesMap = <String, Map<String, dynamic>>{};
      for (final completedEx in completedExercises) {
        if (completedEx is Map<String, dynamic>) {
          final exerciseName = completedEx['exerciseName'] as String?;
          if (exerciseName != null) {
            completedExercisesMap[exerciseName] = completedEx;
          }
        }
      }

      for (final exData in planExercises) {
        final exerciseName = exData['name'] as String? ?? 'Exercise';
        final planSets = exData['sets'] as int?;
        final planReps = exData['reps'];

        // Check if we have completed data for this exercise
        final completedEx = completedExercisesMap[exerciseName];
        final hasCompletedData = completedEx != null && isCompleted;

        // Generate sets based on planSets and planReps, or use completedExercises data if available
        List<domain.WorkoutSet> sets = [];
        if (planSets != null && planSets > 0) {
          if (hasCompletedData) {
            // Use completedExercises data to populate sets with actual weight, reps, rpe
            final actualSets = completedEx['actualSets'] as int? ?? planSets;
            final actualReps = completedEx['actualReps'] as List<dynamic>?;
            final weightUsed = (completedEx['weightUsed'] as num?)?.toDouble() ?? 0.0;

            // Generate sets with completed data
            sets = List.generate(actualSets, (index) {
              final reps = actualReps != null && index < actualReps.length
                  ? (actualReps[index] as num?)?.toInt() ?? 0
                  : (planReps is int ? planReps : (planReps is String ? int.tryParse(planReps) ?? 0 : 0));

              return domain.WorkoutSet(
                id: const Uuid().v4(),
                weight: weightUsed,
                reps: reps,
                rpe: null, // RPE not stored in completedExercises
                isCompleted: true, // Mark as completed since we have completed data
              );
            });
          } else {
            // Generate empty sets based on planSets (for non-completed workouts)
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
        }

        exercises.add(
          domain.Exercise(
            id: '',
            name: exerciseName,
            targetMuscle: exData['targetMuscle'] as String? ?? '',
            sets: sets,
            restSeconds: exData['restSeconds'] as int?,
            notes: exData['notes'] as String?,
            planSets: planSets,
            planReps: planReps,
          ),
        );
      }
    } else if (logData['weeklyPlanId'] is Map) {
      // 2. FALLBACK: Try to extract exercises from weeklyPlanId.workouts[].exercises using dayOfWeek
      // (Only if planExercises is missing - this should rarely happen if backend is correct)
      final weeklyPlanId = logData['weeklyPlanId'] as Map<String, dynamic>;
      final logDayOfWeek = logData['dayOfWeek'] as int?; // Plan day index (1-7)

      if (logDayOfWeek != null && weeklyPlanId['workouts'] is List) {
        final workouts = weeklyPlanId['workouts'] as List<dynamic>;

        // Find matching workout day in plan using log.dayOfWeek (plan day index)
        Map<String, dynamic>? planWorkout;
        for (final workoutDay in workouts) {
          if (workoutDay is Map<String, dynamic>) {
            final workoutDayOfWeek = workoutDay['dayOfWeek'] as int?;
            if (workoutDayOfWeek == logDayOfWeek) {
              planWorkout = workoutDay;
              break;
            }
          }
        }

        if (planWorkout != null && planWorkout['exercises'] is List) {
          final planExercises = planWorkout['exercises'] as List<dynamic>;

          for (final exData in planExercises) {
            final planSets = exData['sets'] as int?;
            final planReps = exData['reps'];

            // Generate sets based on planSets and planReps
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
                  id: const Uuid().v4(),
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
        }
      }
    }

    // 3. LAST RESORT FALLBACK: Try completedExercises if planExercises and plan workouts not available
    if (exercises.isEmpty && logData['completedExercises'] != null && logData['completedExercises'] is List) {
      final completedExercises = logData['completedExercises'] as List<dynamic>;
      for (final exData in completedExercises) {
        // Try to extract planSets from actualSets if available
        final actualSets = exData['actualSets'] as int?;
        final planSets = actualSets ?? exData['planSets'] as int?;
        final planReps = exData['reps'] ?? exData['planReps'];

        // Generate sets based on planSets
        List<domain.WorkoutSet> sets = [];
        if (planSets != null && planSets > 0) {
          int defaultReps = 0;
          if (planReps != null) {
            if (planReps is int) {
              defaultReps = planReps;
            } else if (planReps is String) {
              final match = RegExp(r'(\d+)').firstMatch(planReps);
              if (match != null) {
                defaultReps = int.tryParse(match.group(1) ?? '0') ?? 0;
              }
            }
          }

          sets = List.generate(planSets, (index) {
            return domain.WorkoutSet(
              id: const Uuid().v4(),
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
            name: exData['exerciseName'] as String? ?? 'Exercise',
            targetMuscle: exData['targetMuscle'] as String? ?? '',
            sets: sets,
            restSeconds: exData['restSeconds'] as int?,
            notes: exData['notes'] as String?,
            planSets: planSets,
            planReps: planReps,
          ),
        );
      }
    }

    if (exercises.isEmpty) {
      debugPrint('[WorkoutRepositoryImpl] ⚠️ WARNING: No exercises found in workout log data');
    }

    return Workout(
      id: serverId,
      serverId: serverId,
      name: workoutName,
      planId: planId,
      scheduledDate: workoutDate,
      dayOfWeek: dayOfWeek,
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
      return workout;
    }

    // Try to parse workout.id as integer (Isar ID)
    int? isarId = int.tryParse(workout.id);

    // If workout.id is not an integer, try to find workout by serverId
    if (isarId == null && workout.serverId != null) {
      final existingWorkout = await _localDataSource.getWorkoutByServerId(workout.serverId!);
      if (existingWorkout != null) {
        isarId = existingWorkout.id;
      }
    }

    if (isarId == null) {
      throw Exception('Invalid workout ID: ${workout.id} (serverId: ${workout.serverId})');
    }

    final collection = WorkoutMapper.toCollection(workout, isarId: isarId);
    collection.isDirty = true;
    collection.updatedAt = DateTime.now();

    // Save workout collection
    await _localDataSource.saveWorkout(collection);

    // Load existing exercises from database to get their Isar IDs
    final existingExercises = await _localDataSource.getExercisesForWorkout(isarId);

    // Create a map of exercise name -> Isar ID for quick lookup
    // Only map exercises that are actually linked to this workout (defensive check)
    final exerciseIdMap = <String, int>{};
    final duplicateNames = <String, List<int>>{}; // Track duplicates for validation

    for (final existingExercise in existingExercises) {
      // Validate exercise has valid ID
      if (existingExercise.id <= 0) {
        debugPrint(
          '[WorkoutRepositoryImpl:Update] ⚠️ WARNING: Found exercise "${existingExercise.name}" with invalid ID: ${existingExercise.id}',
        );
        continue;
      }

      // Track duplicates
      if (exerciseIdMap.containsKey(existingExercise.name)) {
        if (!duplicateNames.containsKey(existingExercise.name)) {
          duplicateNames[existingExercise.name] = [exerciseIdMap[existingExercise.name]!];
        }
        duplicateNames[existingExercise.name]!.add(existingExercise.id);
        debugPrint('[WorkoutRepositoryImpl] ⚠️ WARNING: Duplicate exercise name "${existingExercise.name}" found');
        // Use the first one found (most recent might be better, but first is safer)
      } else {
        exerciseIdMap[existingExercise.name] = existingExercise.id;
      }
    }

    // Convert exercises to collections and save them with sets
    final exerciseCollections = <ExerciseCollection>[];

    for (final exercise in workout.exercises) {
      // Validate exercise name is not empty
      if (exercise.name.isEmpty) {
        debugPrint('[WorkoutRepositoryImpl] ⚠️ WARNING: Exercise has empty name, skipping');
        continue;
      }

      // Try to find existing Isar ID for this exercise
      final existingIsarId = exerciseIdMap[exercise.name];
      if (existingIsarId != null && existingIsarId > 0) {
        exerciseCollections.add(ExerciseMapper.toCollection(exercise, isarId: existingIsarId));
      } else {
        exerciseCollections.add(ExerciseMapper.toCollection(exercise));
      }
    }

    // Validation: Check if we have exercises to save
    if (exerciseCollections.isEmpty && workout.exercises.isNotEmpty) {
      debugPrint(
        '[WorkoutRepositoryImpl] ⚠️ WARNING: No exercises converted but workout has ${workout.exercises.length} exercises',
      );
    }

    // Save exercises and sets to database with error handling
    try {
      await _localDataSource.saveExercisesForWorkout(isarId, exerciseCollections);

      // Verify that exercises were saved correctly
      final verifyExercises = await _localDataSource.getExercisesForWorkout(isarId);

      if (verifyExercises.length != exerciseCollections.length) {
        debugPrint(
          '[WorkoutRepositoryImpl] ⚠️ WARNING: Exercise count mismatch after save. Expected ${exerciseCollections.length}, got ${verifyExercises.length}',
        );
      }

      // Verify sets were saved
      int totalSetsSaved = 0;
      for (final verifyExercise in verifyExercises) {
        totalSetsSaved += verifyExercise.sets.length;
      }
      int totalSetsExpected = exerciseCollections.fold(0, (sum, ex) => sum + ex.sets.length);

      if (totalSetsSaved != totalSetsExpected) {
        debugPrint('[WorkoutRepositoryImpl] ⚠️ WARNING: Set count mismatch after save');
      }
    } catch (e, stackTrace) {
      debugPrint('[WorkoutRepositoryImpl] ❌ ERROR saving exercises and sets: $e');
      debugPrint('[WorkoutRepositoryImpl] Stack trace: $stackTrace');
      // Don't throw - allow workout collection to be saved even if exercises fail
      // This ensures workout state is preserved
    }

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

  @override
  Future<bool> canUnlockNextWeek(String userId) async {
    final remoteDataSource = _remoteDataSource;
    if (remoteDataSource == null) {
      debugPrint('[WorkoutRepository] ✗ RemoteDataSource is null');
      return false;
    }

    if (userId.isEmpty) {
      debugPrint('[WorkoutRepository] ✗ userId is empty - cannot check unlock status');
      return false;
    }

    try {
      final result = await remoteDataSource.canUnlockNextWeek(userId);
      return result;
    } catch (e) {
      debugPrint('[WorkoutRepository] ✗ Error canUnlockNextWeek: $e');
      return false;
    }
  }

  @override
  Future<int?> migrateDayOfWeek(Workout workout) async {
    if (workout.dayOfWeek != null) {
      return workout.dayOfWeek; // Already has dayOfWeek
    }

    // If workout has serverId, try to fetch from backend
    final remoteDataSource = _remoteDataSource;
    if (workout.serverId != null && remoteDataSource != null) {
      try {
        final allLogs = await remoteDataSource.getAllWorkoutLogs();
        Map<String, dynamic>? logData;
        try {
          logData = allLogs.firstWhere((log) => log['_id']?.toString() == workout.serverId) as Map<String, dynamic>?;
        } catch (e) {
          logData = null;
        }

        if (logData != null && logData.isNotEmpty && logData['dayOfWeek'] != null) {
          final dayOfWeek = logData['dayOfWeek'] as int;
          return dayOfWeek;
        }
      } catch (e) {
        debugPrint('[WorkoutRepositoryImpl] ⚠️ Migration: Error fetching dayOfWeek: $e');
      }
    }

    // If planId exists, try to calculate from planStartDate
    // TODO: This requires planStartDate which may not be available
    // For now, return null and let finishWorkout() handle the error

    return null;
  }

  @override
  Future<void> requestNextWeek(String userId) async {
    final remoteDataSource = _remoteDataSource;
    if (remoteDataSource == null) {
      debugPrint('[WorkoutRepository] ✗ ERROR - Remote data source not available');
      throw Exception('Remote data source not available');
    }

    try {
      final response = await remoteDataSource.requestNextWeek(userId);

      // Update local currentPlanId cache
      if (response != null) {
        final newPlanId = response['currentPlanId']?.toString();

        if (newPlanId != null) {
          await _localDataSource.saveCurrentPlanId(userId, newPlanId);
        } else {
          debugPrint('[WorkoutRepository] ⚠️ WARNING - Response received but no currentPlanId in response');
        }
      } else {
        debugPrint('[WorkoutRepository] ⚠️ WARNING - Response is null');
      }
    } catch (e) {
      debugPrint('[WorkoutRepository] ✗ ERROR - Unlock failed: $e');
      rethrow; // Let UI handle error
    }
  }

  @override
  Future<String?> migratePlanId(Workout workout) async {
    if (workout.planId != null) {
      return workout.planId; // Already has planId
    }

    // If workout has serverId, try to fetch from backend
    final remoteDataSource = _remoteDataSource;
    if (workout.serverId != null && remoteDataSource != null) {
      try {
        final allLogs = await remoteDataSource.getAllWorkoutLogs();
        Map<String, dynamic>? logData;
        try {
          logData = allLogs.firstWhere((log) => log['_id']?.toString() == workout.serverId) as Map<String, dynamic>?;
        } catch (e) {
          logData = null;
        }

        if (logData != null && logData.isNotEmpty) {
          // Try to extract weeklyPlanId from WorkoutLog
          // weeklyPlanId can be either a String or a Map (populated object)
          final weeklyPlanIdValue = logData['weeklyPlanId'];
          String? planId;

          if (weeklyPlanIdValue is String) {
            planId = weeklyPlanIdValue;
          } else if (weeklyPlanIdValue is Map) {
            final weeklyPlanIdMap = weeklyPlanIdValue as Map<String, dynamic>;
            planId = weeklyPlanIdMap['_id']?.toString();
          }

          if (planId != null && planId.isNotEmpty) {
            return planId;
          }
        }
      } catch (e) {
        debugPrint('[WorkoutRepositoryImpl] ⚠️ Migration: Error fetching planId: $e');
      }
    }

    return null;
  }
}
