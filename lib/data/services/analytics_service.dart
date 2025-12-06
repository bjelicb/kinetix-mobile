import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

class AnalyticsService {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  
  AnalyticsService(this._remoteDataSource, this._localDataSource);
  
  /// Fetch trainer's clients from backend
  Future<List<Map<String, dynamic>>> getTrainerClients() async {
    try {
      final response = await _remoteDataSource.getTrainerClients();
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching trainer clients: $e');
      }
      return [];
    }
  }
  
  /// Calculate weekly adherence rate (0-100) for a specific client
  /// Returns list of 7 values representing Mon-Sun adherence percentages
  Future<List<double>> calculateWeeklyAdherence(String? clientId) async {
    try {
      if (kIsWeb) {
        // On web, analytics calculations are not supported yet
        return List.filled(7, 0.0);
      }
      
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      // Get all workouts from local storage
      final allWorkouts = await _localDataSource.getWorkouts();
      
      // Filter workouts for the past week
      final weekWorkouts = (allWorkouts as List<dynamic>).where((workout) {
        final workoutDate = workout.scheduledDate as DateTime;
        final daysDiff = workoutDate.difference(startOfWeek).inDays;
        return daysDiff >= 0 && daysDiff < 7;
      }).toList();
      
      // Group by day of week (0 = Monday, 6 = Sunday)
      final dailyWorkouts = <int, List<dynamic>>{};
      for (final workout in weekWorkouts) {
        final workoutDate = workout.scheduledDate as DateTime;
        final dayOfWeek = (workoutDate.weekday - 1) % 7;
        dailyWorkouts.putIfAbsent(dayOfWeek, () => <dynamic>[]).add(workout);
      }
      
      // Calculate adherence per day
      final adherenceList = <double>[];
      for (int day = 0; day < 7; day++) {
        final dayWorkouts = dailyWorkouts[day] ?? [];
        if (dayWorkouts.isEmpty) {
          adherenceList.add(0.0);
        } else {
          final completed = dayWorkouts.where((w) => (w as dynamic).isCompleted as bool).length;
          final adherence = (completed / dayWorkouts.length) * 100;
          adherenceList.add(adherence);
        }
      }
      
      return adherenceList;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating weekly adherence: $e');
      }
      return List.filled(7, 0.0);
    }
  }
  
  /// Calculate overall adherence rate for a client (0-100)
  Future<double> calculateOverallAdherence(String? clientId) async {
    try {
      if (kIsWeb) {
        return 0.0;
      }
      
      final allWorkouts = await _localDataSource.getWorkouts() as List<dynamic>;
      
      if (allWorkouts.isEmpty) return 0.0;
      
      final completed = allWorkouts.where((w) => (w as dynamic).isCompleted as bool).length;
      return (completed / allWorkouts.length) * 100;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating overall adherence: $e');
      }
      return 0.0;
    }
  }
  
  /// Get total number of workouts for a client
  Future<int> getTotalWorkouts(String? clientId) async {
    try {
      if (kIsWeb) {
        return 0;
      }
      
      final allWorkouts = await _localDataSource.getWorkouts() as List<dynamic>;
      return allWorkouts.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting total workouts: $e');
      }
      return 0;
    }
  }
  
  /// Get completed workouts count for a client
  Future<int> getCompletedWorkouts(String? clientId) async {
    try {
      if (kIsWeb) {
        return 0;
      }
      
      final allWorkouts = await _localDataSource.getWorkouts() as List<dynamic>;
      return allWorkouts.where((w) => (w as dynamic).isCompleted as bool).length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting completed workouts: $e');
      }
      return 0;
    }
  }
  
  /// Calculate strength progression for a specific exercise
  /// Returns list of FlSpot data points (day index, max weight)
  Future<Map<String, List<Map<String, double>>>> getStrengthProgression({
    String? clientId,
    int daysBack = 30,
  }) async {
    try {
      if (kIsWeb) {
        return {};
      }
      
      final allWorkouts = await _localDataSource.getWorkouts() as List<dynamic>;
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: daysBack));
      
      // Filter workouts in date range
      final recentWorkouts = allWorkouts.where((workout) {
        final workoutDate = (workout as dynamic).scheduledDate as DateTime;
        final isCompleted = (workout as dynamic).isCompleted as bool;
        return workoutDate.isAfter(startDate) && isCompleted;
      }).toList();
      
      // Group by exercise name and extract max weight per day
      final exerciseData = <String, Map<int, double>>{}; // exercise -> dayIndex -> maxWeight
      
      for (final workout in recentWorkouts) {
        final workoutDate = (workout as dynamic).scheduledDate as DateTime;
        final workoutId = (workout as dynamic).id as int;
        final daysSinceStart = workoutDate.difference(startDate).inDays;
        
        // Get exercises for this workout
        final exercises = await _localDataSource.getExercisesForWorkout(workoutId) as List<dynamic>;
        
        for (final exercise in exercises) {
          final exerciseName = (exercise as dynamic).name as String;
          final exerciseSets = (exercise as dynamic).sets as List<dynamic>;
          exerciseData.putIfAbsent(exerciseName, () => {});
          
          // Find max weight for this exercise in this workout
          double maxWeight = 0.0;
          for (final set in exerciseSets) {
            final isSetCompleted = (set as dynamic).isCompleted as bool;
            final setWeight = (set as dynamic).weight as double;
            if (isSetCompleted && setWeight > maxWeight) {
              maxWeight = setWeight;
            }
          }
          
          // Update max weight for this day (keep the maximum)
          if (maxWeight > 0) {
            final currentMax = exerciseData[exerciseName]![daysSinceStart] ?? 0.0;
            exerciseData[exerciseName]![daysSinceStart] = maxWeight > currentMax 
                ? maxWeight 
                : currentMax;
          }
        }
      }
      
      // Convert to format expected by chart (day index, weight)
      final result = <String, List<Map<String, double>>>{};
      for (final entry in exerciseData.entries) {
        final spots = entry.value.entries.map((e) => <String, double>{
          'x': e.key.toDouble(),
          'y': e.value,
        }).toList();
        spots.sort((a, b) => a['x']!.compareTo(b['x']!));
        result[entry.key] = spots;
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating strength progression: $e');
      }
      return {};
    }
  }
}
