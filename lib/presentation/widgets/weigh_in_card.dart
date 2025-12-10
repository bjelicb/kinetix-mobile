import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_feedback.dart';
import 'gradient_card.dart';
import 'neon_button.dart';

class WeighInCard extends StatelessWidget {
  final Map<String, dynamic>? latestWeighIn;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const WeighInCard({
    super.key,
    this.latestWeighIn,
    this.isLoading = false,
    this.onRefresh,
  });

  bool get _isMonday => DateTime.now().weekday == 1;

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  int _daysSinceLastWeighIn(DateTime lastDate) {
    final now = DateTime.now();
    final difference = now.difference(lastDate);
    return difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GradientCard(
          child: SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    final hasWeighIn = latestWeighIn != null;
    final weight = hasWeighIn ? (latestWeighIn!['weight'] as num?)?.toDouble() : null;
    final weighInDate = hasWeighIn && latestWeighIn!['date'] != null
        ? DateTime.parse(latestWeighIn!['date'])
        : null;
    final isWeightSpike = latestWeighIn?['isWeightSpike'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GradientCard(
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
                      Row(
                        children: [
                          Icon(
                            Icons.scale_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Weekly Weigh-In',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (_isMonday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'RECOMMENDED',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (hasWeighIn && weight != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              weight.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, left: 4),
                              child: Text(
                                'kg',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (weighInDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(weighInDate),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${_daysSinceLastWeighIn(weighInDate)} days ago',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        if (isWeightSpike) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: AppColors.error,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Weight spike detected',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'No weigh-in recorded',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record your first weigh-in',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                NeonButton(
                  text: 'Record',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () async {
                    AppHaptic.medium();
                    // Wait for weigh-in page to return, and refresh if successful
                    final result = await context.push('/weigh-in');
                    if (result == true && onRefresh != null) {
                      onRefresh!();
                    }
                  },
                ),
              ],
            ),
            if (_isMonday && (!hasWeighIn || (weighInDate != null && _daysSinceLastWeighIn(weighInDate) > 0))) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isMonday && !hasWeighIn
                            ? 'Recommended: Record your weigh-in on Monday (plan start day) for accurate weekly tracking.'
                            : 'Recommended: Record your weigh-in on Monday for the best tracking accuracy.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

