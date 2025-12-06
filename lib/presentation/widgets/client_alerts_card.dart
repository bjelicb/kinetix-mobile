import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';

class ClientAlert {
  final String id;
  final String clientName;
  final String message;
  final String type; // 'missed_workout', 'low_adherence', 'injury', etc.
  final DateTime timestamp;

  ClientAlert({
    required this.id,
    required this.clientName,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class ClientAlertsCard extends StatelessWidget {
  final List<ClientAlert> alerts;
  final Function(String clientId)? onAlertTap;

  const ClientAlertsCard({
    super.key,
    this.alerts = const [],
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mock alerts if empty
    final displayAlerts = alerts.isEmpty ? _getMockAlerts() : alerts;

    if (displayAlerts.isEmpty) {
      return GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs/2),
            Text(
              'All clients are on track',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Client Alerts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs/2),
                decoration: BoxDecoration(
                  gradient: AppGradients.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${displayAlerts.length}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...displayAlerts.take(5).map((alert) => _buildAlertItem(context, alert)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, ClientAlert alert) {
    IconData icon;
    Color color;

    switch (alert.type) {
      case 'missed_workout':
        icon = Icons.event_busy_rounded;
        color = AppColors.error;
        break;
      case 'low_adherence':
        icon = Icons.trending_down_rounded;
        color = AppColors.warning;
        break;
      case 'injury':
        icon = Icons.medical_services_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.info_rounded;
        color = AppColors.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          if (onAlertTap != null) {
            onAlertTap!(alert.id);
          } else {
            // Navigate to client details (placeholder)
            context.go('/client/${alert.id}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.clientName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs/2),
                    Text(
                      alert.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatTime(alert.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  List<ClientAlert> _getMockAlerts() {
    return [
      ClientAlert(
        id: '1',
        clientName: 'John Doe',
        message: 'Missed scheduled workout',
        type: 'missed_workout',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ClientAlert(
        id: '2',
        clientName: 'Jane Smith',
        message: 'Low workout adherence this week',
        type: 'low_adherence',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ClientAlert(
        id: '3',
        clientName: 'Mike Johnson',
        message: 'Reported minor injury',
        type: 'injury',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

