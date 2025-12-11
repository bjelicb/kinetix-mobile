import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';

/// Dialog for clearing cache confirmation
class ClearCacheDialog {
  /// Shows the clear cache confirmation dialog
  /// Returns true if user confirmed, false otherwise
  static Future<bool> show(BuildContext context) async {
    AppHaptic.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear Cache?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: const Text('This will clear all cached images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AppHaptic.medium();
              Navigator.of(context).pop(true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}

