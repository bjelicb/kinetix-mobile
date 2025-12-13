import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/workout.dart';
import '../../pages/calendar/utils/calendar_utils.dart';
import 'calendar_workout_item_widget.dart';

/// Selected day workouts widget showing list or empty state
class SelectedDayWorkoutsWidget extends StatelessWidget {
  final List<Workout> workouts;
  final DateTime selectedDay;
  final Function(Workout) onWorkoutTap;

  const SelectedDayWorkoutsWidget({
    super.key,
    required this.workouts,
    required this.selectedDay,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayWorkouts = CalendarUtils.getWorkoutsForDate(workouts, selectedDay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CalendarUtils.formatSelectedDate(selectedDay), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: dayWorkouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts scheduled',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a day with a workout to view details',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: dayWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = dayWorkouts[index];
                      return CalendarWorkoutItem(workout: workout, onTap: () => onWorkoutTap(workout));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
