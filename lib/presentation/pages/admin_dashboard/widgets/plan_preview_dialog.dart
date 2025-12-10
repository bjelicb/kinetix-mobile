import 'package:flutter/material.dart';
import '../plan_builder/models/plan_builder_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../widgets/gradient_card.dart';

class PlanPreviewDialog extends StatelessWidget {
  final String planName;
  final String difficulty;
  final String description;
  final List<WorkoutDayData> workoutDays;
  
  const PlanPreviewDialog({
    super.key,
    required this.planName,
    required this.difficulty,
    required this.description,
    required this.workoutDays,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Plan Preview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Plan Name
              Text(
                planName.isEmpty ? 'Untitled Plan' : planName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Difficulty Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  difficulty,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Workout Days
              Text(
                'Workout Days (${workoutDays.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              if (workoutDays.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No workout days added',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...workoutDays.map((day) => _buildWorkoutDayPreview(context, day)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDayPreview(BuildContext context, WorkoutDayData day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.dayOfWeek}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day.isRestDay ? 'Rest Day' : (day.name.isEmpty ? 'Unnamed Workout' : day.name),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (day.isRestDay)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'REST',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          if (!day.isRestDay && day.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...day.exercises.map((exercise) => _buildExercisePreview(context, exercise)),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisePreview(BuildContext context, ExerciseData exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exercise.name.isEmpty ? 'Unnamed Exercise' : exercise.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            '${exercise.sets}x${exercise.reps}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${exercise.restSeconds}s',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

