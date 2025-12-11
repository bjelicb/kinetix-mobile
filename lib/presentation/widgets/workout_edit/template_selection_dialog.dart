import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../data/models/workout_template.dart';
import '../glass_bottom_sheet.dart';
import '../gradient_card.dart';

/// Template selection dialog
class TemplateSelectionDialog {
  static Future<WorkoutTemplate?> show({
    required BuildContext context,
    required List<WorkoutTemplate> templates,
  }) async {
    return await GlassBottomSheet.show<WorkoutTemplate>(
      context: context,
      title: 'Select Template',
      height: MediaQuery.of(context).size.height * 0.7,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GradientCard(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  AppHaptic.medium();
                  Navigator.of(context).pop(template);
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${template.exercises.length} exercises',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

