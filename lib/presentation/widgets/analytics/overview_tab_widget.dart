import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../controllers/analytics_controller.dart';
import '../gradient_card.dart';
import '../adherence_chart.dart';
import '../shimmer_loader.dart';

/// Widget for overview tab showing charts and stats
class OverviewTabWidget extends StatelessWidget {
  final ClientAnalytics? analytics;
  final bool isLoading;

  const OverviewTabWidget({
    super.key,
    required this.analytics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || analytics == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ShimmerCard(height: 250),
          const SizedBox(height: 32),
          const ShimmerCard(height: 100),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Weekly Adherence',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AdherenceChart(
          adherenceData: analytics!.weeklyAdherence,
          isLoading: isLoading,
        ),
        const SizedBox(height: 32),
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GradientCard(
                gradient: AppGradients.primary,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${analytics!.overallAdherence.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adherence',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientCard(
                gradient: AppGradients.secondary,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${analytics!.totalWorkouts}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Workouts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

