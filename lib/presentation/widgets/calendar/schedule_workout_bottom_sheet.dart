import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../neon_button.dart';

/// Schedule workout bottom sheet
class ScheduleWorkoutBottomSheet {
  static void show({
    required BuildContext context,
    required DateTime selectedDay,
    required VoidCallback onCreateNew,
    required VoidCallback onSelectExisting,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Schedule Workout',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Selected date: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: 'Create New Workout',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.pop(context);
                onCreateNew();
              },
              gradient: AppGradients.primary,
            ),
            const SizedBox(height: 12),
            NeonButton(
              text: 'Select Existing Workout',
              icon: Icons.list_rounded,
              onPressed: () {
                Navigator.pop(context);
                onSelectExisting();
              },
              gradient: AppGradients.secondary,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

