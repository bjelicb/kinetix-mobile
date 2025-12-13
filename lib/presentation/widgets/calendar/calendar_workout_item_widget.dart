import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../domain/entities/workout.dart';
import '../../pages/calendar/utils/calendar_utils.dart';
import '../gradient_card.dart';

/// Workout item widget for calendar workout list
class CalendarWorkoutItem extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const CalendarWorkoutItem({super.key, required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GradientCard(
        gradient: workout.isCompleted ? AppGradients.success : AppGradients.card,
        padding: const EdgeInsets.all(AppSpacing.md),
        pressEffect: true,
        onTap: () {
          AppHaptic.selection();
          onTap();
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: workout.isCompleted ? AppGradients.success : AppGradients.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                workout.isCompleted ? Icons.check_rounded : Icons.fitness_center_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        CalendarUtils.formatTime(workout.scheduledDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (workout.exercises.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.fitness_center_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.exercises.length} ${workout.exercises.length == 1 ? 'exercise' : 'exercises'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (workout.isCompleted)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}
