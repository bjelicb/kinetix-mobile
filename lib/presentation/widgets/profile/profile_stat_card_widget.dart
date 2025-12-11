import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../gradient_card.dart';

class ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Gradient gradient;

  const ProfileStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final cardWidth = isSmallPhone ? 96.0 : 108.0;
    final cardHeight = isSmallPhone ? 96.0 : 108.0;
    
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: GradientCard(
        gradient: gradient,
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.zero,
        elevation: 6,
        pressEffect: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

