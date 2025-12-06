import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../presentation/widgets/filter_bottom_sheet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

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
    _repository = WorkoutRepositoryImpl(localDataSource, remoteDataSource);
    
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
            workout.exercises.any((exercise) =>
                exercise.name.toLowerCase().contains(query));
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
                  workout.scheduledDate.isBefore(
                    filterOptions.customDateRange!.end.add(const Duration(days: 1)),
                  );
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
        return workout.exercises.any((exercise) =>
            exercise.targetMuscle == filterOptions!.muscleGroup);
      }).toList();
    }

    return filtered;
  }
}

