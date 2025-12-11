import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';

/// Apply template confirmation dialog
class ApplyTemplateDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String templateName,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Apply Template?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'This will replace your current exercises with the "$templateName" template exercises.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

