import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../domain/entities/workout.dart';
import '../../../../domain/entities/plan.dart';
import '../../../../core/theme/app_colors.dart';

/// Workout status enum for calendar display
enum WorkoutStatus { completed, missed, pending, restDay, locked }

/// Calendar utility functions
class CalendarUtils {
  /// Format selected date as "Today", "Tomorrow", or "DD Month YYYY"
  static String formatSelectedDate(DateTime selectedDay) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    if (isSameDay(selected, today)) {
      return 'Today';
    } else if (isSameDay(selected, today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return '${selectedDay.day} ${getMonthName(selectedDay.month)} ${selectedDay.year}';
    }
  }

  /// Format time as "HH:MM"
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get month name from month number (1-12)
  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Format date for workout display as "DD/MM/YYYY"
  static String formatDateForWorkout(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Group workouts by date
  /// Returns map where key is date (without time) and value is list of workouts
  static Map<DateTime, List<Workout>> groupWorkoutsByDate(List<Workout> workouts) {
    final workoutsByDate = <DateTime, List<Workout>>{};
    for (final workout in workouts) {
      final date = DateTime(workout.scheduledDate.year, workout.scheduledDate.month, workout.scheduledDate.day);
      workoutsByDate.putIfAbsent(date, () => []).add(workout);
    }
    return workoutsByDate;
  }

  /// Filter workouts for a specific date
  static List<Workout> getWorkoutsForDate(List<Workout> workouts, DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);

    return workouts.where((workout) {
      final workoutDate = DateTime(workout.scheduledDate.year, workout.scheduledDate.month, workout.scheduledDate.day);
      return isSameDay(selectedDate, workoutDate);
    }).toList();
  }

  /// Get workout status for a specific date
  static WorkoutStatus getWorkoutStatus(Workout? workout, DateTime date, Plan? activePlan) {
    if (workout != null) {
      if (workout.isRestDay) {
        return WorkoutStatus.restDay;
      }
      if (workout.isCompleted) {
        return WorkoutStatus.completed;
      }
      if (workout.isMissed) {
        return WorkoutStatus.missed;
      }
      return WorkoutStatus.pending;
    }

    // No workout log exists
    // If there's an active plan, the date might be pending (workout not yet logged)
    // If no active plan, the date is locked
    if (activePlan != null) {
      return WorkoutStatus.pending;
    }

    return WorkoutStatus.locked;
  }

  /// Get color for workout status
  static Color getStatusColor(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.completed:
        return AppColors.success; // Green
      case WorkoutStatus.missed:
        return AppColors.error; // Red
      case WorkoutStatus.pending:
        return AppColors.warning; // Orange
      case WorkoutStatus.restDay:
        return AppColors.textSecondary; // Gray
      case WorkoutStatus.locked:
        return AppColors.textSecondary.withValues(alpha: 0.3); // Light gray
    }
  }
}
