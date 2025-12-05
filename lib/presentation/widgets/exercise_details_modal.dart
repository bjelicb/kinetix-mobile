import 'package:flutter/material.dart';
import '../../domain/entities/exercise.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/widgets/glass_bottom_sheet.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../core/utils/haptic_feedback.dart';

class ExerciseDetailsModal {
  static Future<Exercise?> show({
    required BuildContext context,
    required Exercise exercise,
  }) async {
    return await GlassBottomSheet.show<Exercise>(
      context: context,
      height: 500,
      child: _ExerciseDetailsContent(exercise: exercise),
    );
  }
}

class _ExerciseDetailsContent extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseDetailsContent({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Exercise Name
        Text(
          exercise.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Category and Target Muscle
        Row(
          children: [
            if (exercise.category != null) ...[
              _buildInfoChip(
                context,
                Icons.category_rounded,
                exercise.category!,
              ),
              const SizedBox(width: 8),
            ],
            _buildInfoChip(
              context,
              Icons.fitness_center_rounded,
              exercise.targetMuscle,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Equipment
        if (exercise.equipment != null && exercise.equipment!.isNotEmpty) ...[
          Text(
            'Equipment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exercise.equipment!.map((eq) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  eq,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Instructions
        if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
          Text(
            'Instructions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              exercise.instructions!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Add to Workout Button
        NeonButton(
          text: 'Add to Workout',
          icon: Icons.add_rounded,
          onPressed: () {
            AppHaptic.medium();
            Navigator.of(context).pop(exercise);
          },
          gradient: AppGradients.primary,
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

