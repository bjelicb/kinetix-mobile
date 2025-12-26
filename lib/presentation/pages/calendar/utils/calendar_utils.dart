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

  /// Calculate the last unlocked day from workouts
  ///
  /// Logic:
  /// 1. If currentPlanId is set → use workouts from that plan (unlocked plan)
  /// 2. If currentPlanId is null → find the FIRST plan from workout logs (by earliest date)
  ///    This ensures we use the plan that should be unlocked next, not the newest assigned plan
  ///
  /// This is the last workout day that client has access to.
  /// Days after this are LOCKED until client unlocks next week.
  static DateTime? getLastUnlockedDay(List<Workout> workouts, String? currentPlanId) {
    if (workouts.isEmpty) {
      return null;
    }

    List<Workout> unlockedWorkouts;

    if (currentPlanId != null) {
      // Filter workouts ONLY from currentPlanId (unlocked plan)
      unlockedWorkouts = workouts.where((w) => w.planId == currentPlanId).toList();
    } else {
      // currentPlanId is null - find the FIRST plan from workout logs (by earliest date)
      // This is the plan that should be unlocked next (not the newest assigned plan)
      // Group workouts by planId
      final workoutsByPlan = <String, List<Workout>>{};
      for (final workout in workouts) {
        if (workout.planId != null) {
          workoutsByPlan.putIfAbsent(workout.planId!, () => []).add(workout);
        }
      }

      if (workoutsByPlan.isEmpty) {
        return null;
      }

      // Find the plan with the EARLIEST workout date (first plan to unlock)
      String? firstPlanId;
      DateTime? firstPlanEarliestDate;

      for (final entry in workoutsByPlan.entries) {
        final planWorkouts = entry.value;
        DateTime? earliestDate;
        for (final workout in planWorkouts) {
          final date = DateTime(workout.scheduledDate.year, workout.scheduledDate.month, workout.scheduledDate.day);
          if (earliestDate == null || date.isBefore(earliestDate)) {
            earliestDate = date;
          }
        }

        // Choose plan with earliest start date (first plan to unlock)
        if (earliestDate != null && (firstPlanEarliestDate == null || earliestDate.isBefore(firstPlanEarliestDate))) {
          firstPlanId = entry.key;
          firstPlanEarliestDate = earliestDate;
        }
      }

      if (firstPlanId == null) {
        return null;
      }

      // IMPORTANT: If currentPlanId is null, return null to show all workout logs
      // This allows viewing workout logs from previous plans even without currentPlanId
      // Unlock logic will only apply to future plans (days after the last workout date)
      return null; // Return null to show all workout logs
    }

    if (unlockedWorkouts.isEmpty) {
      return null;
    }

    // Find latest date from unlocked workouts
    DateTime? latestDate;
    for (final workout in unlockedWorkouts) {
      final date = DateTime(workout.scheduledDate.year, workout.scheduledDate.month, workout.scheduledDate.day);
      if (latestDate == null || date.isAfter(latestDate)) {
        latestDate = date;
      }
    }

    return latestDate;
  }

  /// Get workout status for a specific date
  ///
  /// IMPORTANT: This method shows workout status for ALL plans (current and previous).
  /// If lastUnlockedDay is provided, it applies unlock logic (locks days after lastUnlockedDay).
  /// If lastUnlockedDay is null, it shows status without unlock logic (for previous plans or when no currentPlanId).
  static WorkoutStatus getWorkoutStatus(
    Workout? workout,
    DateTime date,
    Plan? activePlan, // Keep for backward compatibility
    DateTime? lastUnlockedDay, // If null, no unlock logic applied (for previous plans)
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // If workout exists, return its status (regardless of which plan it's from)
    // This ensures workout logs from all plans are visible
    if (workout != null) {
      // Apply unlock logic only if lastUnlockedDay is provided (for current plan)
      // If lastUnlockedDay is null, show workout status without unlock logic
      if (lastUnlockedDay != null) {
        // Check if day is locked (after lastUnlockedDay)
        if (dateOnly.isAfter(lastUnlockedDay)) {
          return WorkoutStatus.locked;
        }
      }

      // Return workout status
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

    // No workout log exists for this day
    // If it's a future day (after today), it's locked
    // If it's a past day without workout, it's also locked (no plan for that day)
    if (dateOnly.isAfter(todayOnly)) {
      return WorkoutStatus.locked; // Future day without workout
    }
    
    // Past day without workout - show as locked but with faded appearance
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
