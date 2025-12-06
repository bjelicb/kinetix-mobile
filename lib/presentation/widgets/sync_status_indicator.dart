import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';
import 'package:intl/intl.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncStatusIndicator({
    super.key,
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case SyncStatus.syncing:
        statusColor = AppColors.primary;
        statusIcon = Icons.sync_rounded;
        statusText = 'Syncing...';
        break;
      case SyncStatus.success:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = lastSyncTime != null
            ? 'Last sync: ${DateFormat('MMM dd, HH:mm').format(lastSyncTime!)}'
            : 'Synced';
        break;
      case SyncStatus.error:
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
        statusText = errorMessage ?? 'Sync failed';
        break;
      case SyncStatus.idle:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.sync_disabled_rounded;
        statusText = lastSyncTime != null
            ? 'Last sync: ${DateFormat('MMM dd, HH:mm').format(lastSyncTime!)}'
            : 'Never synced';
        break;
    }

    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (status == SyncStatus.syncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
