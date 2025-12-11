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
  final VoidCallback onDelete;

  const CalendarWorkoutItem({
    super.key,
    required this.workout,
    required this.onTap,
    required this.onDelete,
  });

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
                gradient: workout.isCompleted
                    ? AppGradients.success
                    : AppGradients.primary,
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    CalendarUtils.formatTime(workout.scheduledDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (workout.isCompleted)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            IconButton(
              icon: const Icon(
                Icons.delete_rounded,
                color: AppColors.error,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

