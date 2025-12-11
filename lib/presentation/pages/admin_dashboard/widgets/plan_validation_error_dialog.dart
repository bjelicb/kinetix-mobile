import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PlanValidationErrorDialog extends StatelessWidget {
  final List<String> errors;

  const PlanValidationErrorDialog({
    super.key,
    required this.errors,
  });

  static Future<void> show(BuildContext context, List<String> errors) {
    return showDialog(
      context: context,
      builder: (_) => PlanValidationErrorDialog(errors: errors),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Validation Errors'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('• $e'),
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

