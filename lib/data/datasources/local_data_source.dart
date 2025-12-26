import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:isar/isar.dart';

// Conditional import for Isar extensions
// On mobile: isar_extensions.dart re-exports all model files
// On web: isar_extensions_stub.dart re-exports all stub files
import '../models/isar_extensions.dart' if (dart.library.html) '../models/isar_extensions_stub.dart';
import '../../services/isar_service.dart';

class LocalDataSource {
  Future<Isar?> get _isar async {
    if (kIsWeb) return null;
    return await IsarService.instance;
  }

  // User Operations
  Future<UserCollection?> getUserByServerId(String serverId) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    return await isar.userCollections.filter().serverIdEqualTo(serverId).findFirst();
  }

  Future<List<UserCollection>> getUsers() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    return await isar.userCollections.where().findAll();
  }

  Future<void> saveUser(UserCollection user) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.userCollections.put(user);
    });
  }

  Future<void> saveCurrentPlanId(String userId, String? currentPlanId) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      final user = await isar.userCollections.filter().serverIdEqualTo(userId).findFirst();
      if (user != null) {
        user.currentPlanId = currentPlanId;
        await isar.userCollections.put(user);
      }
    });
  }

  Future<String?> getCurrentPlanId(String userId) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    final user = await isar.userCollections.filter().serverIdEqualTo(userId).findFirst();
    return user?.currentPlanId;
  }

  // Workout Operations
  Future<List<WorkoutCollection>> getWorkouts() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    return await isar.workoutCollections.where().findAll();
  }

  Future<WorkoutCollection?> getWorkoutById(int id) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    return await isar.workoutCollections.get(id);
  }

  Future<WorkoutCollection?> getWorkoutByServerId(String serverId) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    return await isar.workoutCollections.filter().serverIdEqualTo(serverId).findFirst();
  }

  Future<void> saveWorkout(WorkoutCollection workout) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      // Check if workout with same serverId already exists
      if (workout.serverId.isNotEmpty) {
        final existing = await isar.workoutCollections.filter().serverIdEqualTo(workout.serverId).findFirst();
        if (existing != null) {
          // Update existing workout instead of creating new one
          workout.id = existing.id; // Preserve Isar ID
        }
      }
      await isar.workoutCollections.put(workout);
    });
  }

  Future<List<WorkoutCollection>> getDirtyWorkouts() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    return await isar.workoutCollections.filter().isDirtyEqualTo(true).findAll();
  }

  Future<void> deleteWorkout(int id) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.workoutCollections.delete(id);
    });
  }

  // Exercise Operations
  Future<List<ExerciseCollection>> getExercisesForWorkout(int workoutId) async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];

    final workout = await isar.workoutCollections.get(workoutId);
    if (workout == null) {
      debugPrint('[LocalDataSource] ❌ Workout $workoutId not found');
      return [];
    }

    await workout.exercises.load();
    final exercises = workout.exercises.toList();

    // Check for duplicates
    if (exercises.isNotEmpty) {
      final exerciseNames = exercises.map((e) => e.name).toList();
      final uniqueNames = exerciseNames.toSet();
      if (exerciseNames.length != uniqueNames.length) {
        debugPrint('[LocalDataSource] ⚠️ WARNING: Found ${exerciseNames.length - uniqueNames.length} duplicate exercises!');
      }
    }

    return exercises;
  }

  Future<void> saveExercise(ExerciseCollection exercise) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.exerciseCollections.put(exercise);
    });
  }

  /// Save exercises and link them to a workout
  Future<void> saveExercisesForWorkout(int workoutId, List<ExerciseCollection> exercises) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;

    final workout = await isar.workoutCollections.get(workoutId);
    if (workout == null) {
      debugPrint('[LocalDataSource] ❌ Workout $workoutId not found, cannot save exercises');
      return;
    }

    // Check existing exercises BEFORE clearing
    await workout.exercises.load();
    final existingExercises = workout.exercises.toList();

    await isar.writeTxn(() async {
      // Delete existing ExerciseCollection objects from database FIRST (not just links)
      // This prevents duplicates and ensures we always have the latest data from backend
      for (final existingExercise in existingExercises) {
        await isar.exerciseCollections.delete(existingExercise.id);
      }
      
      // Clear existing exercise links
      workout.exercises.clear();

      // Save each exercise and add to links (avoid duplicates)
      final savedExerciseIds = <int>{};
      
      for (final exercise in exercises) {
        // Defensive check: Validate exercise has valid name
        if (exercise.name.isEmpty) {
          debugPrint('[LocalDataSource] ⚠️ WARNING: Exercise has empty name, skipping');
          continue;
        }
        
        // Save exercise to collection (put() automatically updates if ID exists, creates new if not)
        try {
          await isar.exerciseCollections.put(exercise);
        } catch (e) {
          debugPrint('[LocalDataSource] ❌ ERROR saving exercise "${exercise.name}": $e');
          // Continue with next exercise instead of failing entire operation
          continue;
        }

        // Only add if not already added (check by ID)
        if (!savedExerciseIds.contains(exercise.id)) {
          workout.exercises.add(exercise);
          savedExerciseIds.add(exercise.id);
        }
      }

      // Save the workout with updated links
      await workout.exercises.save();
      await isar.workoutCollections.put(workout);
    });

    // Verify final count
    await workout.exercises.load();
    final exercisesList = workout.exercises.toList();
    final finalCount = exercisesList.length;
    
    // Validation: Check if count matches
    if (finalCount != exercises.length) {
      debugPrint('[LocalDataSource] ⚠️ WARNING: Exercise count mismatch! Expected ${exercises.length}, got $finalCount');
    }
  }

  // CheckIn Operations
  Future<List<CheckInCollection>> getAllCheckIns() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) {
      debugPrint('[LocalDataSource] Isar is null, returning empty list');
      return [];
    }
    try {
      final all = await isar.checkInCollections.where().findAll();
      // Sort by timestamp descending (newest first)
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      debugPrint('[LocalDataSource] Loaded ${all.length} check-ins');
      return all;
    } catch (e, stackTrace) {
      debugPrint('[LocalDataSource] ERROR loading check-ins: $e');
      debugPrint('[LocalDataSource] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<CheckInCollection?> getCheckInById(int id) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    return await isar.checkInCollections.get(id);
  }

  Future<void> deleteCheckIn(int id) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    await isar.writeTxn(() async {
      await isar.checkInCollections.delete(id);
    });
  }

  Future<List<CheckInCollection>> getUnsyncedCheckIns() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    return await isar.checkInCollections.filter().isSyncedEqualTo(false).findAll();
  }

  Future<List<CheckInCollection>> getCheckInsWithoutPhotoUrl() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    return await isar.checkInCollections.filter().photoUrlIsNull().findAll();
  }

  /// Get today's check-in if it exists
  Future<CheckInCollection?> getTodayCheckIn() async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;

    final now = DateTime.now();
    final allCheckIns = await isar.checkInCollections.where().findAll();

    // Find check-in for today
    for (final checkIn in allCheckIns) {
      final checkInDate = DateTime(checkIn.timestamp.year, checkIn.timestamp.month, checkIn.timestamp.day);
      final todayDate = DateTime(now.year, now.month, now.day);

      if (checkInDate == todayDate) {
        return checkIn;
      }
    }

    return null;
  }

  /// Get workouts scheduled for today
  Future<List<WorkoutCollection>> getTodayWorkouts() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];

    final now = DateTime.now();
    final allWorkouts = await isar.workoutCollections.where().findAll();

    // Filter workouts for today
    final todayWorkouts = <WorkoutCollection>[];
    for (final workout in allWorkouts) {
      final workoutDate = DateTime(workout.scheduledDate.year, workout.scheduledDate.month, workout.scheduledDate.day);
      final todayDate = DateTime(now.year, now.month, now.day);

      if (workoutDate == todayDate) {
        todayWorkouts.add(workout);
      }
    }

    return todayWorkouts;
  }

  Future<void> saveCheckIn(CheckInCollection checkIn) async {
    debugPrint('[LocalDataSource] ═══════════════════════════════════════');
    debugPrint('[LocalDataSource] saveCheckIn() START');

    if (kIsWeb) {
      debugPrint('[LocalDataSource] Web platform - skipping Isar save');
      debugPrint('[LocalDataSource] ═══════════════════════════════════════');
      return;
    }

    final isar = await _isar;
    if (isar == null) {
      debugPrint('[LocalDataSource] ❌ Isar is null - cannot save');
      debugPrint('[LocalDataSource] ═══════════════════════════════════════');
      return;
    }

    debugPrint('[LocalDataSource] Check-in data to save:');
    debugPrint('[LocalDataSource]   - Photo local path: ${checkIn.photoLocalPath}');
    debugPrint('[LocalDataSource]   - Photo URL: ${checkIn.photoUrl}');
    debugPrint('[LocalDataSource]   - Timestamp: ${checkIn.timestamp}');
    debugPrint('[LocalDataSource]   - Is Synced: ${checkIn.isSynced}');
    debugPrint('[LocalDataSource]   - GPS Latitude: ${checkIn.latitude ?? "NULL"}');
    debugPrint('[LocalDataSource]   - GPS Longitude: ${checkIn.longitude ?? "NULL"}');

    await isar.writeTxn(() async {
      await isar.checkInCollections.put(checkIn);
    });

    debugPrint('[LocalDataSource] ✅ Check-in saved successfully with ID: ${checkIn.id}');
    debugPrint('[LocalDataSource] ═══════════════════════════════════════');
  }

  // Plan Operations
  Future<PlanCollection?> getPlanById(String planId) async {
    debugPrint('[LocalDataSource] getPlanById() START - planId: $planId');
    if (kIsWeb) {
      debugPrint('[LocalDataSource] ✗ Web platform - returning null');
      return null;
    }
    final isar = await _isar;
    if (isar == null) {
      debugPrint('[LocalDataSource] ✗ Isar is null - returning null');
      return null;
    }
    try {
      final result = await isar.planCollections.filter().planIdEqualTo(planId).findFirst();
      if (result != null) {
        debugPrint('[LocalDataSource] ✓ Plan found: ${result.name} (ID: ${result.id})');
      } else {
        debugPrint('[LocalDataSource] ✗ Plan not found with ID: $planId');
      }
      return result;
    } catch (e) {
      debugPrint('[LocalDataSource] ✗✗✗ ERROR getting plan by ID: $e');
      return null;
    }
  }

  Future<List<PlanCollection>> getAllPlans() async {
    debugPrint('[LocalDataSource] getAllPlans() START');
    if (kIsWeb) {
      debugPrint('[LocalDataSource] ✗ Web platform - returning empty list');
      return [];
    }
    final isar = await _isar;
    if (isar == null) {
      debugPrint('[LocalDataSource] ✗ Isar is null - returning empty list');
      return [];
    }
    try {
      final result = await isar.planCollections.where().findAll();
      debugPrint('[LocalDataSource] ✓ Found ${result.length} plans in local database');
      for (final plan in result) {
        debugPrint('[LocalDataSource]   - Plan: ${plan.name} (ID: ${plan.planId}, Isar ID: ${plan.id})');
      }
      return result;
    } catch (e) {
      debugPrint('[LocalDataSource] ✗✗✗ ERROR getting all plans: $e');
      return [];
    }
  }

  Future<List<PlanCollection>> getPlansByTrainer(String trainerId) async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    try {
      return await isar.planCollections.filter().trainerIdEqualTo(trainerId).findAll();
    } catch (e) {
      debugPrint('[LocalDataSource] ERROR getting plans by trainer: $e');
      return [];
    }
  }

  Future<List<PlanCollection>> getDirtyPlans() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    try {
      return await isar.planCollections.filter().isDirtyEqualTo(true).findAll();
    } catch (e) {
      debugPrint('[LocalDataSource] ERROR getting dirty plans: $e');
      return [];
    }
  }

  /// Get active plan (plan with workouts scheduled for today or in the future)
  Future<PlanCollection?> getActivePlan() async {
    debugPrint('[LocalDataSource:ActivePlan] Checking for active plan');
    if (kIsWeb) {
      debugPrint('[LocalDataSource:ActivePlan] Web platform - returning null');
      return null;
    }

    final isar = await _isar;
    if (isar == null) {
      debugPrint('[LocalDataSource:ActivePlan] Isar is null - returning null');
      return null;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all workouts scheduled for today or in the future
      final futureWorkouts = await isar.workoutCollections
          .filter()
          .scheduledDateGreaterThan(today.subtract(const Duration(days: 1)))
          .findAll();

      debugPrint('[LocalDataSource:ActivePlan] Found ${futureWorkouts.length} future/current workouts');

      if (futureWorkouts.isEmpty) {
        debugPrint('[LocalDataSource:ActivePlan] No active plan found (no future workouts)');
        return null;
      }

      // Get all plans and return the first one (assuming one active plan per user)
      final plans = await isar.planCollections.where().findAll();

      if (plans.isEmpty) {
        debugPrint('[LocalDataSource:ActivePlan] No plans found in database');
        return null;
      }

      final activePlan = plans.first;
      debugPrint('[LocalDataSource:ActivePlan] Found active plan: ${activePlan.name} (${activePlan.planId})');
      return activePlan;
    } catch (e, stackTrace) {
      debugPrint('[LocalDataSource:ActivePlan] ERROR: $e');
      debugPrint('[LocalDataSource:ActivePlan] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> savePlan(PlanCollection plan) async {
    debugPrint('[LocalDataSource] savePlan() START - planId: ${plan.planId}, name: ${plan.name}');
    if (kIsWeb) {
      debugPrint('[LocalDataSource] ✗ Web platform - skip save');
      return;
    }
    final isar = await _isar;
    if (isar == null) {
      debugPrint('[LocalDataSource] ✗ Isar is null - skip save');
      return;
    }
    try {
      await isar.writeTxn(() async {
        await isar.planCollections.put(plan);
      });
      debugPrint('[LocalDataSource] ✓ Plan saved: ${plan.name} (planId: ${plan.planId}, Isar ID: ${plan.id})');
      debugPrint('[LocalDataSource] → isDirty: ${plan.isDirty}, workoutDays: ${plan.workoutDays.length}');
    } catch (e) {
      debugPrint('[LocalDataSource] ✗✗✗ ERROR saving plan: $e');
    }
  }

  // AI Messages Operations
  Future<List<AIMessageCollection>> getAIMessages(String clientId) async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    try {
      final messages = await isar.aIMessageCollections.filter().clientIdEqualTo(clientId).findAll();
      // Sort by createdAt descending (newest first)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('[LocalDataSource] Loaded ${messages.length} AI messages for client $clientId');
      return messages;
    } catch (e) {
      debugPrint('[LocalDataSource] Error loading AI messages: $e');
      return [];
    }
  }

  Future<void> saveAIMessages(List<AIMessageCollection> messages) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    try {
      await isar.writeTxn(() async {
        for (final message in messages) {
          await isar.aIMessageCollections.put(message);
        }
      });
      debugPrint('[LocalDataSource] ✓ Saved ${messages.length} AI messages');
    } catch (e) {
      debugPrint('[LocalDataSource] ✗ Error saving AI messages: $e');
    }
  }

  Future<void> updateAIMessageReadStatus(String messageId, bool isRead) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    try {
      final message = await isar.aIMessageCollections.filter().serverIdEqualTo(messageId).findFirst();
      if (message != null) {
        await isar.writeTxn(() async {
          message.isRead = isRead;
          message.updatedAt = DateTime.now();
          await isar.aIMessageCollections.put(message);
        });
        debugPrint('[LocalDataSource] ✓ Updated AI message $messageId read status: $isRead');
      }
    } catch (e) {
      debugPrint('[LocalDataSource] ✗ Error updating AI message read status: $e');
    }
  }
}
