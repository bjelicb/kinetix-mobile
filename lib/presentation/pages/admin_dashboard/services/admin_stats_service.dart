import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote_data_source.dart';

/// Service for admin statistics and analytics
/// Handles all stats-related operations with consistent error handling and logging
class AdminStatsService {
  final RemoteDataSource _remoteDataSource;

  AdminStatsService(this._remoteDataSource);

  /// Get admin dashboard statistics
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      debugPrint('[AdminStatsService] Fetching admin stats');
      final stats = await _remoteDataSource.getAdminStats();
      debugPrint('[AdminStatsService] ✓ Fetched stats: ${stats.keys.join(', ')}');
      return stats;
    } catch (e) {
      debugPrint('[AdminStatsService] ✗ Failed to fetch stats: $e');
      rethrow;
    }
  }

  /// Get all workouts (for management)
  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    try {
      debugPrint('[AdminStatsService] Fetching all workouts');
      final workouts = await _remoteDataSource.getAllWorkouts();
      debugPrint('[AdminStatsService] ✓ Fetched ${workouts.length} workouts');
      return workouts;
    } catch (e) {
      debugPrint('[AdminStatsService] ✗ Failed to fetch workouts: $e');
      rethrow;
    }
  }

  /// Get workout statistics
  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      debugPrint('[AdminStatsService] Fetching workout stats');
      final stats = await _remoteDataSource.getWorkoutStats();
      debugPrint('[AdminStatsService] ✓ Fetched workout stats');
      return stats;
    } catch (e) {
      debugPrint('[AdminStatsService] ✗ Failed to fetch workout stats: $e');
      rethrow;
    }
  }

  /// Update workout status
  Future<void> updateWorkoutStatus(String workoutId, bool isCompleted) async {
    try {
      debugPrint('[AdminStatsService] Updating workout $workoutId status to ${isCompleted ? "completed" : "incomplete"}');
      await _remoteDataSource.updateWorkoutStatus(
        workoutId: workoutId,
        isCompleted: isCompleted,
      );
      debugPrint('[AdminStatsService] ✓ Updated workout status');
    } catch (e) {
      debugPrint('[AdminStatsService] ✗ Failed to update workout status: $e');
      rethrow;
    }
  }

  /// Delete workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      debugPrint('[AdminStatsService] Deleting workout: $workoutId');
      await _remoteDataSource.deleteWorkout(workoutId);
      debugPrint('[AdminStatsService] ✓ Deleted workout: $workoutId');
    } catch (e) {
      debugPrint('[AdminStatsService] ✗ Failed to delete workout $workoutId: $e');
      rethrow;
    }
  }
}

