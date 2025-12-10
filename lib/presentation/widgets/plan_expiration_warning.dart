import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import 'gradient_card.dart';

/// Widget to display plan expiration warnings
/// Shows different states based on days remaining:
/// - < 2 days: Warning (orange)
/// - Expired: Error (red)
/// - Active: No warning
class PlanExpirationWarning extends StatelessWidget {
  final DateTime? planEndDate;
  final String planName;
  final VoidCallback? onContactTrainer;
  
  const PlanExpirationWarning({
    super.key,
    required this.planEndDate,
    required this.planName,
    this.onContactTrainer,
  });
  
  @override
  Widget build(BuildContext context) {
    // If no end date, don't show warning
    if (planEndDate == null) {
      debugPrint('[Dashboard:PlanExpiration] No end date for plan "$planName"');
      return const SizedBox.shrink();
    }
    
    final daysRemaining = AppDateUtils.daysUntil(planEndDate!);
    final isExpired = AppDateUtils.isPast(planEndDate!);
    
    debugPrint('[Dashboard:PlanExpiration] Plan end: $planEndDate, Days remaining: $daysRemaining');
    
    // Plan is active with > 2 days remaining
    if (!isExpired && daysRemaining > 2) {
      return const SizedBox.shrink();
    }
    
    // Plan expired
    if (isExpired) {
      debugPrint('[Dashboard:PlanExpiration] ERROR - Plan expired, workouts disabled');
      return _buildExpiredWarning(context);
    }
    
    // Plan expires soon (< 2 days)
    debugPrint('[Dashboard:PlanExpiration] WARNING - Plan expires soon ($daysRemaining days)');
    return _buildExpiringSoonWarning(context, daysRemaining);
  }
  
  Widget _buildExpiredWarning(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      gradient: LinearGradient(
        colors: [
          AppColors.error.withValues(alpha: 0.2),
          AppColors.error.withValues(alpha: 0.1),
        ],
      ),
      borderColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Plan Expired',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your plan "$planName" has expired. Contact your trainer for a new plan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onContactTrainer != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onContactTrainer,
              icon: const Icon(Icons.message_rounded, size: 18),
              label: const Text('Contact Trainer'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildExpiringSoonWarning(BuildContext context, int daysRemaining) {
    final dayText = daysRemaining == 1 ? 'day' : 'days';
    
    return GradientCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      gradient: LinearGradient(
        colors: [
          AppColors.warning.withValues(alpha: 0.2),
          AppColors.warning.withValues(alpha: 0.1),
        ],
      ),
      borderColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Plan Expiring Soon',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your plan "$planName" expires in $daysRemaining $dayText. Contact your trainer to renew.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onContactTrainer != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onContactTrainer,
              icon: const Icon(Icons.message_rounded, size: 18),
              label: const Text('Contact Trainer'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

