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
import '../neon_button.dart';
import '../empty_state.dart';

/// Today's Mission widget showing today's workout or empty state
class TodaysMissionWidget extends ConsumerWidget {
  final Workout? todayWorkout;

  const TodaysMissionWidget({
    super.key,
    required this.todayWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = ThemeUtils.getThemeGradient(theme);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Mission",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (todayWorkout == null)
            EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No workout scheduled',
              message: 'Take a rest day or schedule a workout',
              actionLabel: 'Schedule Workout',
              onAction: () {
                AppHaptic.selection();
                context.go('/calendar');
              },
            )
          else
            GradientCard(
              gradient: LinearGradient(
                colors: themeGradient.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(20),
              showGlow: true,
              pressEffect: true,
              onTap: () {
                AppHaptic.selection();
                context.go('/workout/${todayWorkout!.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayWorkout!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dashboard_date_utils.DateUtils.formatWorkoutDate(todayWorkout!.scheduledDate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (todayWorkout!.isCompleted)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeonButton(
                    text: todayWorkout!.isCompleted ? 'View Details' : 'Start Workout',
                    icon: todayWorkout!.isCompleted ? Icons.visibility : Icons.play_arrow,
                    onPressed: () {
                      AppHaptic.selection();
                      context.go('/workout/${todayWorkout!.id}');
                    },
                    gradient: AppGradients.secondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

