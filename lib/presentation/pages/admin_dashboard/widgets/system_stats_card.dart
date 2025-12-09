import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../core/theme/gradients.dart';
import '../../../widgets/gradient_card.dart';
import 'stat_item.dart';

class SystemStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const SystemStatsCard({super.key, required this.stats});

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
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'System Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: StatItem(
                  label: 'Total Users',
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatItem(
                  label: 'Trainers',
                  value: '${stats['totalTrainers'] ?? 0}',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: StatItem(
                  label: 'Clients',
                  value: '${stats['totalClients'] ?? 0}',
                  icon: Icons.people_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatItem(
                  label: "Today's Check-ins",
                  value: '${stats['todayCheckIns'] ?? 0}',
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          if (stats['activeTrainers'] != null || stats['totalPlans'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (stats['activeTrainers'] != null) ...[
                  Expanded(
                    child: StatItem(
                      label: 'Active Trainers',
                      value: '${stats['activeTrainers'] ?? 0}',
                      icon: Icons.verified_user_rounded,
                    ),
                  ),
                  if (stats['totalPlans'] != null) const SizedBox(width: AppSpacing.sm),
                ],
                if (stats['totalPlans'] != null)
                  Expanded(
                    child: StatItem(
                      label: 'Total Plans',
                      value: '${stats['totalPlans'] ?? 0}',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
              ],
            ),
          ],
          if (stats['totalWorkoutsCompleted'] != null || stats['pendingCheckIns'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (stats['totalWorkoutsCompleted'] != null) ...[
                  Expanded(
                    child: StatItem(
                      label: 'Workouts Completed',
                      value: '${stats['totalWorkoutsCompleted'] ?? 0}',
                      icon: Icons.done_all_rounded,
                    ),
                  ),
                  if (stats['pendingCheckIns'] != null) const SizedBox(width: AppSpacing.sm),
                ],
                if (stats['pendingCheckIns'] != null)
                  Expanded(
                    child: StatItem(
                      label: 'Pending Check-ins',
                      value: '${stats['pendingCheckIns'] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SystemStatsLoadingCard extends StatelessWidget {
  const SystemStatsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class SystemStatsErrorCard extends StatelessWidget {
  final Object error;

  const SystemStatsErrorCard({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Failed to load system stats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () {
              // Just trigger a rebuild; actual refresh handled by parent refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pull to refresh to retry'),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

