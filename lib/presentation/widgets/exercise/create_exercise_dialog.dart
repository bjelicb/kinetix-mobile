import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Dialog for creating a new exercise (placeholder)
class CreateExerciseDialog {
  /// Shows the create exercise dialog
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Exercise'),
        content: const Text('Exercise creation will be implemented later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

