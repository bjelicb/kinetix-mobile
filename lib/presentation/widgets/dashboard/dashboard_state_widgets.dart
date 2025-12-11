import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../shimmer_loader.dart';

/// Loading state widget for dashboard
class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ShimmerCard(height: 200),
        const SizedBox(height: AppSpacing.md),
        ShimmerCard(height: 120),
        const SizedBox(height: AppSpacing.md),
        ShimmerCard(height: 120),
      ],
    );
  }
}

/// Error state widget for dashboard
class DashboardErrorState extends StatelessWidget {
  final dynamic error;

  const DashboardErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

