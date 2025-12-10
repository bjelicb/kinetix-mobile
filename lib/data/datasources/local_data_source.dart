import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Conditional imports - only import Isar on non-web platforms
// Isar is used via dynamic calls, no direct import needed
import '../models/user_collection.dart' if (dart.library.html) '../models/user_collection_stub.dart';
import '../models/workout_collection.dart' if (dart.library.html) '../models/workout_collection_stub.dart';
import '../models/exercise_collection.dart' if (dart.library.html) '../models/exercise_collection_stub.dart';
import '../models/checkin_collection.dart' if (dart.library.html) '../models/checkin_collection_stub.dart';
import '../models/plan_collection.dart' if (dart.library.html) '../models/plan_collection_stub.dart';
import '../../services/isar_service.dart';

class LocalDataSource {
  Future<dynamic> get _isar async {
    if (kIsWeb) return null;
    return await IsarService.instance;
  }
  
  // User Operations
  Future<UserCollection?> getUserByServerId(String serverId) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    // Use dynamic to avoid type errors on web
    final isarInstance = isar;
    return await (isarInstance as dynamic).userCollections.filter().serverIdEqualTo(serverId).findFirst();
  }
  
  Future<List<UserCollection>> getUsers() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    return await (isarInstance as dynamic).userCollections.where().findAll();
  }
  
  Future<void> saveUser(UserCollection user) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    await (isarInstance as dynamic).writeTxn(() async {
      await (isarInstance as dynamic).userCollections.put(user);
    });
  }
  
  // Workout Operations
  Future<List<WorkoutCollection>> getWorkouts() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    return await (isarInstance as dynamic).workoutCollections.where().findAll();
  }
  
  Future<WorkoutCollection?> getWorkoutById(int id) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    final isarInstance = isar;
    return await (isarInstance as dynamic).workoutCollections.get(id);
  }
  
  Future<WorkoutCollection?> getWorkoutByServerId(String serverId) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    final isarInstance = isar;
    return await (isarInstance as dynamic).workoutCollections.filter().serverIdEqualTo(serverId).findFirst();
  }
  
  Future<void> saveWorkout(WorkoutCollection workout) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    await (isarInstance as dynamic).writeTxn(() async {
      await (isarInstance as dynamic).workoutCollections.put(workout);
    });
  }
  
  Future<List<WorkoutCollection>> getDirtyWorkouts() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    return await (isarInstance as dynamic).workoutCollections.filter().isDirtyEqualTo(true).findAll();
  }
  
  Future<void> deleteWorkout(int id) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    await (isarInstance as dynamic).writeTxn(() async {
      await (isarInstance as dynamic).workoutCollections.delete(id);
    });
  }
  
  // Exercise Operations
  Future<List<ExerciseCollection>> getExercisesForWorkout(int workoutId) async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    final workout = await (isarInstance as dynamic).workoutCollections.get(workoutId);
    if (workout == null) return [];
    
    await (workout as dynamic).exercises.load();
    return (workout as dynamic).exercises.toList();
  }
  
  Future<void> saveExercise(ExerciseCollection exercise) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    await (isarInstance as dynamic).writeTxn(() async {
      await (isarInstance as dynamic).exerciseCollections.put(exercise);
    });
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
      final isarInstance = isar;
      // Use collection() directly instead of extension method (extensions don't work with dynamic)
      final collection = isarInstance.collection<CheckInCollection>();
      final all = await collection.where().findAll();
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
    final isarInstance = isar;
    final collection = isarInstance.collection<CheckInCollection>();
    return await collection.get(id);
  }
  
  Future<void> deleteCheckIn(int id) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    final collection = isarInstance.collection<CheckInCollection>();
    await isarInstance.writeTxn(() async {
      await collection.delete(id);
    });
  }
  
  Future<List<CheckInCollection>> getUnsyncedCheckIns() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    final collection = isarInstance.collection<CheckInCollection>();
    return await collection.filter().isSyncedEqualTo(false).findAll();
  }
  
  Future<List<CheckInCollection>> getCheckInsWithoutPhotoUrl() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    final collection = isarInstance.collection<CheckInCollection>();
    return await collection.filter().photoUrlIsNull().findAll();
  }
  
  /// Get today's check-in if it exists
  Future<CheckInCollection?> getTodayCheckIn() async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    
    final now = DateTime.now();
    
    final isarInstance = isar;
    final collection = isarInstance.collection<CheckInCollection>();
    final allCheckIns = await collection.where().findAll();
    
    // Find check-in for today
    for (final checkIn in allCheckIns) {
      final checkInDate = DateTime(
        checkIn.timestamp.year,
        checkIn.timestamp.month,
        checkIn.timestamp.day,
      );
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
    
    final isarInstance = isar;
    final allWorkouts = await (isarInstance as dynamic).workoutCollections.where().findAll();
    
    // Filter workouts for today
    final todayWorkouts = <WorkoutCollection>[];
    for (final workout in allWorkouts) {
      final workoutDate = DateTime(
        workout.scheduledDate.year,
        workout.scheduledDate.month,
        workout.scheduledDate.day,
      );
      final todayDate = DateTime(now.year, now.month, now.day);
      
      if (workoutDate == todayDate) {
        todayWorkouts.add(workout);
      }
    }
    
    return todayWorkouts;
  }
  
  Future<void> saveCheckIn(CheckInCollection checkIn) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    final collection = isarInstance.collection<CheckInCollection>();
    await isarInstance.writeTxn(() async {
      await collection.put(checkIn);
    });
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
      final isarInstance = isar;
      final collection = isarInstance.collection<PlanCollection>();
      final result = await collection.filter().planIdEqualTo(planId).findFirst();
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
      final isarInstance = isar;
      final collection = isarInstance.collection<PlanCollection>();
      final result = await collection.where().findAll();
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
      final isarInstance = isar;
      final collection = isarInstance.collection<PlanCollection>();
      return await collection.filter().trainerIdEqualTo(trainerId).findAll();
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
      final isarInstance = isar;
      final collection = isarInstance.collection<PlanCollection>();
      return await collection.filter().isDirtyEqualTo(true).findAll();
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
      final isarInstance = isar;
      final workoutCollection = isarInstance.collection<WorkoutCollection>();
      final futureWorkouts = await workoutCollection
          .filter()
          .scheduledDateGreaterThan(today.subtract(const Duration(days: 1)))
          .findAll();
      
      debugPrint('[LocalDataSource:ActivePlan] Found ${futureWorkouts.length} future/current workouts');
      
      if (futureWorkouts.isEmpty) {
        debugPrint('[LocalDataSource:ActivePlan] No active plan found (no future workouts)');
        return null;
      }
      
      // Get all plans and return the first one (assuming one active plan per user)
      final planCollection = isarInstance.collection<PlanCollection>();
      final plans = await planCollection.where().findAll();
      
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
      final isarInstance = isar;
      final collection = isarInstance.collection<PlanCollection>();
      await isarInstance.writeTxn(() async {
        await collection.put(plan);
      });
      debugPrint('[LocalDataSource] ✓ Plan saved: ${plan.name} (planId: ${plan.planId}, Isar ID: ${plan.id})');
      debugPrint('[LocalDataSource] → isDirty: ${plan.isDirty}, workoutDays: ${plan.workoutDays.length}');
    } catch (e) {
      debugPrint('[LocalDataSource] ✗✗✗ ERROR saving plan: $e');
    }
  }
}
