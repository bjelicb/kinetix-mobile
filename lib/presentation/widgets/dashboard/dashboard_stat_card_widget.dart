import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../gradient_card.dart';

/// Reusable stat card widget for dashboard
class DashboardStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Gradient gradient;

  const DashboardStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    
    return SizedBox(
      height: isSmallPhone ? 88 : 96,
      child: GradientCard(
        gradient: gradient,
        padding: const EdgeInsets.all(12),
        margin: EdgeInsets.zero,
        elevation: 6,
        pressEffect: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isSmallPhone ? 20 : 22,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontSize: isSmallPhone ? 9.5 : 10,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

