import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradients.dart';
import '../../../../widgets/neon_button.dart';

class PlanActionButtons extends StatelessWidget {
  final bool isExistingPlan;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const PlanActionButtons({
    super.key,
    required this.isExistingPlan,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NeonButton(
            text: 'Cancel',
            icon: Icons.close_rounded,
            onPressed: onCancel,
            gradient: LinearGradient(
              colors: [
                AppColors.textSecondary.withValues(alpha: 0.3),
                AppColors.textSecondary.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: NeonButton(
            text: isExistingPlan ? 'Update Plan' : 'Create Plan',
            icon: Icons.save_rounded,
            onPressed: isSaving ? null : onSave,
            gradient: AppGradients.success,
          ),
        ),
      ],
    );
  }
}

