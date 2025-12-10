import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../models/plan_builder_models.dart';
import '../../widgets/workout_day_editor.dart';

/// Workout days section for Plan Builder
/// Manages the list of workout days with add/remove functionality
class WorkoutDaysSection extends StatelessWidget {
  final List<WorkoutDayData> workoutDays;
  final Function(int) onRemoveDay;
  final Function() onAddDay;
  final Function(int, WorkoutDayData) onDayUpdated;

  const WorkoutDaysSection({
    super.key,
    required this.workoutDays,
    required this.onRemoveDay,
    required this.onAddDay,
    required this.onDayUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Workout Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: onAddDay,
              tooltip: 'Add Workout Day',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (workoutDays.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workout days yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a workout day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...workoutDays.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: WorkoutDayEditor(
                key: ValueKey('workout_day_$index'),
                dayData: day,
                onDelete: () => onRemoveDay(index),
                onUpdate: (updatedDay) => onDayUpdated(index, updatedDay),
              ),
            );
          }),
      ],
    );
  }
}

