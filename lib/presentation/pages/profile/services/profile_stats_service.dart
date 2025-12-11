import '../../../../domain/entities/workout.dart';
import '../../../../domain/entities/checkin.dart';
import '../../../../presentation/widgets/pr_tracker.dart';
import '../../../../presentation/widgets/progress_chart.dart';

/// Service for calculating profile statistics
/// Pure calculation functions (no Riverpod dependencies) for better testability
class ProfileStatsService {
  /// Calculate number of completed workouts
  static int calculateCompletedWorkouts(List<Workout> workouts) {
    return workouts.where((w) => w.isCompleted).length;
  }

  /// Calculate total volume (weight * reps) from all completed sets
  static double calculateTotalVolume(List<Workout> workouts) {
    double totalVolume = 0;
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          if (set.isCompleted) {
            totalVolume += set.weight * set.reps;
          }
        }
      }
    }
    return totalVolume;
  }

  /// Calculate check-in streak
  static int calculateStreak(List<CheckIn> checkIns) {
    if (checkIns.isEmpty) return 0;
    
    final sortedCheckIns = List<CheckIn>.from(checkIns)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    int streak = 0;
    DateTime? lastDate;
    
    for (final checkIn in sortedCheckIns) {
      final checkInDate = DateTime(
        checkIn.timestamp.year,
        checkIn.timestamp.month,
        checkIn.timestamp.day,
      );
      
      if (lastDate == null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        if (checkInDate == todayDate || checkInDate == todayDate.subtract(const Duration(days: 1))) {
          streak = 1;
          lastDate = checkInDate;
        } else {
          break;
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (checkInDate == expectedDate) {
          streak++;
          lastDate = checkInDate;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  /// Calculate volume progression for the last 7 workouts
  /// Returns list of ChartDataPoint for graphing
  static List<ChartDataPoint> calculateVolumeProgression(List<Workout> workouts) {
    final sortedWorkouts = List<Workout>.from(workouts)
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    final recentWorkouts = sortedWorkouts.take(7).toList().reversed.toList();
    
    return recentWorkouts.asMap().entries.map((entry) {
      final index = entry.key;
      final workout = entry.value;
      double volume = 0;
      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          if (set.isCompleted) {
            volume += set.weight * set.reps;
          }
        }
      }
      return ChartDataPoint(index.toDouble(), volume);
    }).toList();
  }

  /// Calculate personal records from all workouts
  static List<PersonalRecord> calculatePersonalRecords(List<Workout> workouts) {
    final prs = <String, PersonalRecord>{};
    
    for (final workout in workouts) {
      if (!workout.isCompleted) continue;
      
      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          if (!set.isCompleted) continue;
          
          final key = '${exercise.id}_${set.reps}';
          final existingPR = prs[key];
          
          if (existingPR == null || set.weight > existingPR.weight) {
            prs[key] = PersonalRecord(
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              weight: set.weight,
              reps: set.reps,
              date: workout.scheduledDate,
            );
          }
        }
      }
    }
    
    return prs.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Calculate best exercises (most frequently used)
  /// Returns list of MapEntry(String, int) sorted by frequency (descending)
  static List<MapEntry<String, int>> calculateBestExercises(List<Workout> workouts) {
    final exerciseCounts = <String, int>{};
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        exerciseCounts[exercise.name] = (exerciseCounts[exercise.name] ?? 0) + 1;
      }
    }
    return exerciseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}

