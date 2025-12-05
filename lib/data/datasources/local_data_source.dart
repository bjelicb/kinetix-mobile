import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports - only import Isar on non-web platforms
import 'package:isar/isar.dart' if (dart.library.html) '../../isar_stub.dart';
import '../models/user_collection.dart' if (dart.library.html) '../models/user_collection_stub.dart';
import '../models/workout_collection.dart' if (dart.library.html) '../models/workout_collection_stub.dart';
import '../models/exercise_collection.dart' if (dart.library.html) '../models/exercise_collection_stub.dart';
import '../models/checkin_collection.dart' if (dart.library.html) '../models/checkin_collection_stub.dart';
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
    if (isar == null) return [];
    final isarInstance = isar;
    final all = await (isarInstance as dynamic).checkInCollections.where().findAll();
    // Sort by timestamp descending (newest first)
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }
  
  Future<CheckInCollection?> getCheckInById(int id) async {
    if (kIsWeb) return null;
    final isar = await _isar;
    if (isar == null) return null;
    final isarInstance = isar;
    return await (isarInstance as dynamic).checkInCollections.get(id);
  }
  
  Future<void> deleteCheckIn(int id) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    await (isarInstance as dynamic).writeTxn(() async {
      await (isarInstance as dynamic).checkInCollections.delete(id);
    });
  }
  
  Future<List<CheckInCollection>> getUnsyncedCheckIns() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    return await (isarInstance as dynamic).checkInCollections.filter().isSyncedEqualTo(false).findAll();
  }
  
  Future<List<CheckInCollection>> getCheckInsWithoutPhotoUrl() async {
    if (kIsWeb) return [];
    final isar = await _isar;
    if (isar == null) return [];
    final isarInstance = isar;
    return await (isarInstance as dynamic).checkInCollections.filter().photoUrlIsNull().findAll();
  }
  
  Future<void> saveCheckIn(CheckInCollection checkIn) async {
    if (kIsWeb) return;
    final isar = await _isar;
    if (isar == null) return;
    final isarInstance = isar;
    await (isarInstance as dynamic).writeTxn(() async {
      await (isarInstance as dynamic).checkInCollections.put(checkIn);
    });
  }
}
