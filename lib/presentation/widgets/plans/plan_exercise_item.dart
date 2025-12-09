import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/plan.dart';

class PlanExerciseItem extends StatelessWidget {
  final PlanExercise exercise;

  const PlanExerciseItem({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise icon/number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryStart.withValues(alpha: 0.3),
                  AppColors.primaryEnd.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Sets × Reps
                Row(
                  children: [
                    _buildDetailChip(
                      icon: Icons.repeat_rounded,
                      label: '${exercise.sets} sets',
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.trending_up_rounded,
                      label: '${exercise.reps} reps',
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.timer_outlined,
                      label: exercise.formattedRest,
                    ),
                  ],
                ),
                
                // Target muscle if available
                if (exercise.targetMuscle != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exercise.targetMuscle!,
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                
                // Notes if available
                if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    exercise.notes!,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Video indicator if available
          if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

