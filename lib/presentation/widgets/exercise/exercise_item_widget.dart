import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/exercise.dart';
import '../gradient_card.dart';

/// Widget for displaying a single exercise item in the list
class ExerciseItemWidget extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final Function(Exercise) onTap;
  final Function(Exercise) onToggleSelection;
  final Function(Exercise) onShowDetails;

  const ExerciseItemWidget({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelection,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GradientCard(
        padding: const EdgeInsets.all(16),
        onTap: () => onTap(exercise),
        child: Row(
          children: [
            // Selection Checkbox
            GestureDetector(
              onTap: () => onToggleSelection(exercise),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (exercise.category != null) ...[
                        Text(
                          exercise.category!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        exercise.targetMuscle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              onPressed: () => onShowDetails(exercise),
            ),
          ],
        ),
      ),
    );
  }
}

