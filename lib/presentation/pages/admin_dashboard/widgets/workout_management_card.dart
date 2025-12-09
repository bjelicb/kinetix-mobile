import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../core/theme/gradients.dart';
import '../utils/date_formatters.dart';
import '../../../widgets/cyber_loader.dart';
import '../../../widgets/gradient_card.dart';

class WorkoutManagementCard extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> workouts;
  final Map<String, dynamic>? workoutStats;
  final ValueChanged<Map<String, dynamic>> onWorkoutTap;

  const WorkoutManagementCard({
    super.key,
    required this.isLoading,
    required this.workouts,
    required this.workoutStats,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      showCyberBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Workout Manage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (workoutStats != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.adminAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${workoutStats?['totalWorkouts'] ?? 0} completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else if (workouts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No workouts found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return InkWell(
                    onTap: () => onWorkoutTap(workout),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.adminAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        workout['isCompleted'] == true
                                            ? Icons.check_circle_rounded
                                            : workout['isMissed'] == true
                                                ? Icons.cancel_rounded
                                                : Icons.pending_rounded,
                                        size: 16,
                                        color: workout['isCompleted'] == true
                                            ? AppColors.success
                                            : workout['isMissed'] == true
                                                ? AppColors.error
                                                : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          workout['planName'] ?? 'Unknown Plan',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Client: ${workout['clientName'] ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  if (workout['workoutDate'] != null)
                                    Text(
                                      'Date: ${formatDate(workout['workoutDate'])}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

