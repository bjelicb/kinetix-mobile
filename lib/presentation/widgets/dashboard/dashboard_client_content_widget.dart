import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../domain/entities/workout.dart';
import '../../controllers/theme_controller.dart';
import '../../pages/dashboard/utils/theme_utils.dart';
import '../../pages/dashboard/utils/date_utils.dart' as dashboard_date_utils;
import '../gradient_card.dart';
import '../empty_state.dart';
import 'delete_workout_dialog.dart';

/// Client content widget showing recent workouts list
class DashboardClientContent extends ConsumerWidget {
  final List<Workout> workouts;
  final Function(String) onDeleteWorkout;

  const DashboardClientContent({
    super.key,
    required this.workouts,
    required this.onDeleteWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Workouts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (workouts.isEmpty)
            EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No workouts yet',
              message: 'Start your fitness journey by scheduling your first workout',
              actionLabel: 'Schedule Workout',
              onAction: () {
                AppHaptic.selection();
                context.go('/calendar');
              },
            )
          else
            SizedBox(
              height: workouts.length > 5 ? 400 : null,
              child: ListView.builder(
                shrinkWrap: workouts.length <= 5,
                physics: workouts.length > 5
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: workouts.length > 5 ? 5 : workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GradientCard(
                      gradient: AppGradients.card,
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        AppHaptic.selection();
                        context.go('/workout/${workout.id}');
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: workout.isCompleted
                                  ? AppGradients.success
                                  : LinearGradient(
                                      colors: ThemeUtils.getThemeGradient(ref.watch(themeControllerProvider)).colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              workout.isCompleted
                                  ? Icons.check_rounded
                                  : Icons.fitness_center_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workout.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dashboard_date_utils.DateUtils.formatWorkoutDate(workout.scheduledDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              DeleteWorkoutDialog.show(
                                context,
                                workout.id,
                                ref,
                                onDeleteWorkout,
                              );
                            },
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
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

