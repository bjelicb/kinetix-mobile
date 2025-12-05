import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'neon_button.dart';

enum EmptyStateType {
  noData,
  error,
  loading,
  search,
}

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateType type;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.type = EmptyStateType.noData,
  });

  IconData _getDefaultIcon() {
    switch (type) {
      case EmptyStateType.noData:
        return icon ?? Icons.inbox_rounded;
      case EmptyStateType.error:
        return icon ?? Icons.error_outline_rounded;
      case EmptyStateType.loading:
        return icon ?? Icons.hourglass_empty_rounded;
      case EmptyStateType.search:
        return icon ?? Icons.search_off_rounded;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case EmptyStateType.noData:
        return AppColors.textSecondary;
      case EmptyStateType.error:
        return AppColors.error;
      case EmptyStateType.loading:
        return AppColors.warning;
      case EmptyStateType.search:
        return AppColors.textSecondary;
    }
  }

  Gradient _getGradient() {
    switch (type) {
      case EmptyStateType.noData:
        return AppGradients.card;
      case EmptyStateType.error:
        return AppGradients.orangePink;
      case EmptyStateType.loading:
        return AppGradients.secondary;
      case EmptyStateType.search:
        return AppGradients.card;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _getGradient(),
                shape: BoxShape.circle,
                boxShadow: type == EmptyStateType.error
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _getDefaultIcon(),
                size: 64,
                color: _getIconColor(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              NeonButton(
                text: actionLabel!,
                onPressed: onAction,
                gradient: type == EmptyStateType.error
                    ? AppGradients.orangePink
                    : AppGradients.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

