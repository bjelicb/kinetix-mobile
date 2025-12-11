import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/workout.dart';
import '../../pages/calendar/utils/calendar_utils.dart';
import 'calendar_empty_state_widget.dart';
import 'calendar_workout_item_widget.dart';

/// Selected day workouts widget showing list or empty state
class SelectedDayWorkoutsWidget extends StatelessWidget {
  final List<Workout> workouts;
  final DateTime selectedDay;
  final VoidCallback onScheduleWorkout;
  final Function(Workout) onWorkoutTap;
  final Function(String) onDeleteWorkout;

  const SelectedDayWorkoutsWidget({
    super.key,
    required this.workouts,
    required this.selectedDay,
    required this.onScheduleWorkout,
    required this.onWorkoutTap,
    required this.onDeleteWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final dayWorkouts = CalendarUtils.getWorkoutsForDate(workouts, selectedDay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CalendarUtils.formatSelectedDate(selectedDay),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (dayWorkouts.isEmpty)
            Expanded(
              child: CalendarEmptyState(
                onScheduleWorkout: onScheduleWorkout,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dayWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = dayWorkouts[index];
                  return CalendarWorkoutItem(
                    workout: workout,
                    onTap: () => onWorkoutTap(workout),
                    onDelete: () => onDeleteWorkout(workout.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

