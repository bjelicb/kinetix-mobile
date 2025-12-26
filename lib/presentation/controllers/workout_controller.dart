import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../presentation/widgets/filter_bottom_sheet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'auth_controller.dart';
import 'calendar_controller.dart';
import 'plan_controller.dart';

part 'workout_controller.g.dart';

@riverpod
class WorkoutController extends _$WorkoutController {
  late WorkoutRepository _repository;

  @override
  FutureOr<List<Workout>> build() async {
    final storage = FlutterSecureStorage();
    final localDataSource = LocalDataSource();
    final dio = Dio();
    final remoteDataSource = RemoteDataSource(dio, storage);
    _repository = WorkoutRepositoryImpl(localDataSource, remoteDataSource, storage);

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
    debugPrint('[WorkoutController] ═══════════════════════════════════════');
    debugPrint('[WorkoutController] updateWorkout START - Workout: ${workout.name}, ID: ${workout.id}');
    debugPrint('[WorkoutController] Workout isCompleted: ${workout.isCompleted}');
    debugPrint('[WorkoutController] Workout has ${workout.exercises.length} exercises');
    for (int exIndex = 0; exIndex < workout.exercises.length; exIndex++) {
      final exercise = workout.exercises[exIndex];
      debugPrint('[WorkoutController] Exercise $exIndex: "${exercise.name}" has ${exercise.sets.length} sets');
      for (int setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        final set = exercise.sets[setIndex];
        debugPrint(
          '[WorkoutController] Set $setIndex: isCompleted=${set.isCompleted}, weight=${set.weight}, reps=${set.reps}, rpe=${set.rpe}',
        );
      }
    }
    final updated = await _repository.updateWorkout(workout);
    debugPrint('[WorkoutController] Repository updateWorkout completed');
    debugPrint('[WorkoutController] ═══════════════════════════════════════');

    // Directly update state on BOTH web and mobile instead of reloading
    // This prevents losing changes that haven't been saved yet
    final currentWorkouts = state.valueOrNull ?? [];
    debugPrint('[WorkoutController] Current workouts count: ${currentWorkouts.length}');

    final updatedWorkouts = currentWorkouts.map((w) {
      // Match by id OR serverId
      final isMatch = w.id == workout.id || w.serverId == workout.id || w.id == workout.serverId;
      if (isMatch) {
        debugPrint('[WorkoutController] Matched workout: ${w.name} (id:${w.id}, serverId:${w.serverId})');
        return updated;
      }
      return w;
    }).toList();

    debugPrint('[WorkoutController] Updated workouts list, setting state...');
    state = AsyncValue.data(updatedWorkouts);
    debugPrint('[WorkoutController] ✅ State updated successfully');

    return updated;
  }

  Future<void> deleteWorkout(String id) async {
    await _repository.deleteWorkout(id);
    state = AsyncValue.data(await _repository.getWorkouts());
  }

  /// Force refresh workouts from server (bypasses Isar cache)
  /// This ensures all workout logs are synced from server to Isar
  /// OPTIMIZED: If updatedWorkout is provided, use optimistic update instead of full reload
  Future<void> refreshWorkouts({Workout? updatedWorkout}) async {
    debugPrint('[WorkoutController] refreshWorkouts() - Forcing API refresh');
    
    // Add monitoring logging for refreshWorkouts
    debugPrint('[WorkoutController] 📊 REFRESH_WORKOUTS_METRICS:');
    debugPrint('[WorkoutController]   - Method: ${updatedWorkout != null ? "optimistic_update" : "full_reload"}');
    debugPrint('[WorkoutController]   - Current workout count: ${state.valueOrNull?.length ?? 0}');
    debugPrint('[WorkoutController]   - Timestamp: ${DateTime.now().toIso8601String()}');
    
    try {
      // OPTIMIZATION: If updatedWorkout is provided, use optimistic update
      // This avoids full reload and prevents UI flickering
      if (updatedWorkout != null) {
        debugPrint('[WorkoutController] → Using optimistic update for workout: ${updatedWorkout.name}');
        final currentWorkouts = state.valueOrNull ?? [];
        
        // Update the workout in the list
        final updatedWorkouts = currentWorkouts.map((w) {
          final isMatch = w.id == updatedWorkout.id || 
                         w.serverId == updatedWorkout.id || 
                         w.id == updatedWorkout.serverId ||
                         (w.serverId != null && w.serverId == updatedWorkout.serverId);
          if (isMatch) {
            return updatedWorkout;
          }
          return w;
        }).toList();
        
        // If workout not found, add it
        if (!updatedWorkouts.any((w) => w.id == updatedWorkout.id || w.serverId == updatedWorkout.serverId)) {
          updatedWorkouts.add(updatedWorkout);
        }
        
        state = AsyncValue.data(updatedWorkouts);
        debugPrint('[WorkoutController] ✅ Workout optimistically updated: ${updatedWorkout.name}');
        
        // Trigger background sync to ensure Isar is up to date
        // Don't await - let it happen in background
        _repository.getWorkouts().catchError((e) {
          debugPrint('[WorkoutController] ⚠️ Background sync failed: $e');
          return <Workout>[]; // Return empty list on error
        });
      } else {
        // Full reload if no updated workout provided
        // Invalidate current state to force reload
        final currentWorkouts = state.valueOrNull ?? [];
        state = AsyncValue.data(currentWorkouts); // Keep current state visible (no loading flicker)
        
        // Force reload from repository (which will fetch from API if needed)
        final workouts = await _repository.getWorkouts();
        state = AsyncValue.data(workouts);
        
        debugPrint('[WorkoutController] ✅ Workouts refreshed: ${workouts.length}');
      }
    } catch (e) {
      debugPrint('[WorkoutController] ✗ Failed to refresh workouts: $e');
      // Don't throw - workout is already logged, refresh is just for consistency
      // Keep current state instead of error
      final currentWorkouts = state.valueOrNull ?? [];
      state = AsyncValue.data(currentWorkouts);
    }
  }

  /// Filter workouts based on search query and filter options
  List<Workout> filterWorkouts(String? searchQuery, FilterOptions? filterOptions) {
    final workouts = state.valueOrNull ?? [];
    if (workouts.isEmpty) return [];

    List<Workout> filtered = List.from(workouts);

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((workout) {
        return workout.name.toLowerCase().contains(query) ||
            workout.exercises.any((exercise) => exercise.name.toLowerCase().contains(query));
      }).toList();
    }

    // Apply date filter
    if (filterOptions?.dateFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (filterOptions!.dateFilter!) {
        case DateFilter.today:
          filtered = filtered.where((workout) {
            final workoutDate = DateTime(
              workout.scheduledDate.year,
              workout.scheduledDate.month,
              workout.scheduledDate.day,
            );
            return workoutDate == today;
          }).toList();
          break;
        case DateFilter.thisWeek:
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          filtered = filtered.where((workout) {
            return workout.scheduledDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                workout.scheduledDate.isBefore(today.add(const Duration(days: 7)));
          }).toList();
          break;
        case DateFilter.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          filtered = filtered.where((workout) {
            return workout.scheduledDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                workout.scheduledDate.isBefore(DateTime(now.year, now.month + 1, 1));
          }).toList();
          break;
        case DateFilter.all:
          // No filter
          break;
        case DateFilter.custom:
          if (filterOptions.customDateRange != null) {
            filtered = filtered.where((workout) {
              return workout.scheduledDate.isAfter(
                    filterOptions.customDateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  workout.scheduledDate.isBefore(filterOptions.customDateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }
          break;
      }
    }

    // Apply status filter
    if (filterOptions?.statusFilter != null) {
      switch (filterOptions!.statusFilter!) {
        case StatusFilter.completed:
          filtered = filtered.where((workout) => workout.isCompleted).toList();
          break;
        case StatusFilter.pending:
          filtered = filtered.where((workout) => !workout.isCompleted).toList();
          break;
        case StatusFilter.all:
          // No filter
          break;
      }
    }

    // Apply muscle group filter
    if (filterOptions?.muscleGroup != null) {
      filtered = filtered.where((workout) {
        return workout.exercises.any((exercise) => exercise.targetMuscle == filterOptions!.muscleGroup);
      }).toList();
    }

    return filtered;
  }

  Future<bool> canUnlockNextWeek(String userId) async {
    return await _repository.canUnlockNextWeek(userId);
  }

  Future<void> requestNextWeek(String userId) async {
    await _repository.requestNextWeek(userId);
    // Refresh workouts after unlocking
    state = AsyncValue.data(await _repository.getWorkouts());
  }

  Future<int?> migrateDayOfWeek(Workout workout) async {
    return await _repository.migrateDayOfWeek(workout);
  }

  Future<String?> migratePlanId(Workout workout) async {
    return await _repository.migratePlanId(workout);
  }
}

// Cached provider for canUnlockNextWeek to avoid API spam
@riverpod
Future<bool> canUnlockNextWeek(CanUnlockNextWeekRef ref) async {
  // Get userId from authController (single source of truth)
  final user = await ref.watch(authControllerProvider.future);
  if (user == null) {
    debugPrint('[CanUnlockNextWeek] ✗ No user found - cannot check unlock status');
    return false;
  }

  final userId = user.id;
  debugPrint('[CanUnlockNextWeek] → Using userId from authController: $userId');

  // Keep alive for caching (provider will be cached automatically by Riverpod)
  final controller = ref.read(workoutControllerProvider.notifier);

  try {
    return await controller.canUnlockNextWeek(userId);
  } catch (e) {
    debugPrint('[CanUnlockNextWeek] Error: $e');
    return false; // Graceful fallback
  }
}

// Provider for unlock action with loading state
@riverpod
class UnlockNextWeek extends _$UnlockNextWeek {
  @override
  FutureOr<void> build() async {}

  Future<void> unlock() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[UnlockNextWeek] unlock() START');

      // Get userId from authController (single source of truth)
      final user = await ref.read(authControllerProvider.future);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userId = user.id;
      debugPrint('[UnlockNextWeek] → Using userId from authController: $userId');

      final controller = ref.read(workoutControllerProvider.notifier);
      await controller.requestNextWeek(userId);

      debugPrint('[UnlockNextWeek] → requestNextWeek completed, refreshing providers...');

      // CRITICAL: Invalidate providers in the correct order to ensure proper refresh
      // 1. First refresh user (to get new currentPlanId)
      debugPrint('[UnlockNextWeek] → Step 1: Invalidating authControllerProvider...');
      ref.invalidate(authControllerProvider);
      await Future.delayed(const Duration(milliseconds: 150));

      // 2. Then refresh workouts (to load all workout logs including new plan)
      debugPrint('[UnlockNextWeek] → Step 2: Invalidating workoutControllerProvider...');
      ref.invalidate(workoutControllerProvider);
      await Future.delayed(const Duration(milliseconds: 150));

      // 3. Then refresh plan (to show new current plan)
      debugPrint('[UnlockNextWeek] → Step 3: Invalidating currentPlanProvider...');
      ref.invalidate(currentPlanProvider);
      await Future.delayed(const Duration(milliseconds: 150));

      // 4. Finally refresh calendar (to show workout logs in calendar)
      debugPrint('[UnlockNextWeek] → Step 4: Invalidating calendarDataProvider...');
      ref.invalidate(calendarDataProvider);
      ref.invalidate(canUnlockNextWeekProvider);

      debugPrint('[UnlockNextWeek] ✅ All providers invalidated successfully');
      debugPrint('═══════════════════════════════════════════════════════════');
    });
  }
}
