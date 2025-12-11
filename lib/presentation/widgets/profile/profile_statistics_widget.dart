import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../presentation/controllers/workout_controller.dart';
import '../../../presentation/controllers/checkin_controller.dart';
import '../../pages/profile/services/profile_stats_service.dart';
import '../gradient_card.dart';
import '../progress_chart.dart';
import '../pr_tracker.dart';
import '../shimmer_loader.dart';
import 'profile_stat_card_widget.dart';

class ProfileStatistics extends ConsumerWidget {
  const ProfileStatistics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsState = ref.watch(workoutControllerProvider);
    final checkInsState = ref.watch(checkInControllerProvider);
    
    return workoutsState.when(
      data: (workouts) {
        final completedWorkouts = ProfileStatsService.calculateCompletedWorkouts(workouts);
        final totalVolume = ProfileStatsService.calculateTotalVolume(workouts);
        
        // Calculate streak from check-ins
        final checkIns = checkInsState.valueOrNull ?? [];
        final streak = ProfileStatsService.calculateStreak(checkIns);
        
        final volumeDataPoints = ProfileStatsService.calculateVolumeProgression(workouts);
        final prs = ProfileStatsService.calculatePersonalRecords(workouts);
        final bestExercises = ProfileStatsService.calculateBestExercises(workouts)
            .take(3)
            .toList();

        return Column(
          children: [
            // Quick Stats
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ProfileStatCard(
                    value: '$completedWorkouts',
                    label: 'Completed\nWorkouts',
                    gradient: AppGradients.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ProfileStatCard(
                    value: '$streak',
                    label: 'Day\nStreak',
                    gradient: AppGradients.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ProfileStatCard(
                    value: '${(totalVolume / 1000).toStringAsFixed(1)}k',
                    label: 'Total\nVolume (kg)',
                    gradient: AppGradients.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Volume Progression Chart
            if (volumeDataPoints.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ProgressChart(
                  dataPoints: volumeDataPoints,
                  title: 'Volume Progression (Last 7 Workouts)',
                  yAxisLabel: 'Volume (kg)',
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Personal Records
            if (prs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PRTracker(personalRecords: prs),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Best Exercises
            if (bestExercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GradientCard(
                  gradient: AppGradients.card,
                  padding: const EdgeInsets.all(20),
                  pressEffect: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Exercises',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...bestExercises.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${entry.value}x',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            // View Full History Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () {
                  AppHaptic.selection();
                  context.push('/workout-history');
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('View Full Workout History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ShimmerCard(height: 100, width: 100),
            const SizedBox(width: 12),
            ShimmerCard(height: 100, width: 100),
            const SizedBox(width: 12),
            ShimmerCard(height: 100, width: 100),
          ],
        ),
      ),
      error: (error, stackTrace) => Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Center(
          child: Text('Error loading statistics'),
        ),
      ),
    );
  }
}

