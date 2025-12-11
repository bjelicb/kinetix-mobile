import 'package:table_calendar/table_calendar.dart';
import '../../../../domain/entities/workout.dart';

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
      'December'
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
      final date = DateTime(
        workout.scheduledDate.year,
        workout.scheduledDate.month,
        workout.scheduledDate.day,
      );
      workoutsByDate.putIfAbsent(date, () => []).add(workout);
    }
    return workoutsByDate;
  }

  /// Filter workouts for a specific date
  static List<Workout> getWorkoutsForDate(List<Workout> workouts, DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);

    return workouts.where((workout) {
      final workoutDate = DateTime(
        workout.scheduledDate.year,
        workout.scheduledDate.month,
        workout.scheduledDate.day,
      );
      return isSameDay(selectedDate, workoutDate);
    }).toList();
  }
}

