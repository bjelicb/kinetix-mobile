import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PlanAssignedClientsDialog extends StatelessWidget {
  final int assignedClientsCount;
  final bool isUpdateFailure;

  const PlanAssignedClientsDialog({
    super.key,
    required this.assignedClientsCount,
    this.isUpdateFailure = false,
  });

  static Future<String?> show(BuildContext context, int assignedClientsCount, {bool isUpdateFailure = false}) {
    return showDialog<String>(
      context: context,
      builder: (_) => PlanAssignedClientsDialog(
        assignedClientsCount: assignedClientsCount,
        isUpdateFailure: isUpdateFailure,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(
            isUpdateFailure ? Icons.error_outline_rounded : Icons.warning_rounded,
            color: isUpdateFailure ? AppColors.error : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(isUpdateFailure ? 'Update Failed' : 'Plan is Assigned to Clients'),
          ),
        ],
      ),
      content: Text(
        isUpdateFailure
            ? 'This plan cannot be updated because it is assigned to clients and is not a template.\n\n'
                'Only template plans can be updated when they have assigned clients.\n\n'
                'Choose an option:'
            : 'This plan is assigned to $assignedClientsCount client(s).\n\n'
                '⚠️ Editing this plan will affect all assigned clients.\n\n'
                'Choose an option:',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'new'),
          child: const Text('Create New Plan'),
        ),
        if (!isUpdateFailure)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Update Anyway'),
          ),
      ],
    );
  }
}

