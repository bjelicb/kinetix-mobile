import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors;
import '../../../controllers/admin_controller.dart';
import '../utils/date_formatters.dart';
import '../widgets/plan_detail_item.dart';

Future<void> showWorkoutDetailsModal({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> workout,
  required Future<void> Function() onRefresh,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(workout['planName'] ?? 'Workout Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlanDetailItem(
              label: 'Client',
              value: workout['clientName'] ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            PlanDetailItem(
              label: 'Trainer',
              value: workout['trainerName'] ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            PlanDetailItem(
              label: 'Plan',
              value: workout['planName'] ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            if (workout['workoutDate'] != null)
              PlanDetailItem(
                label: 'Date',
                value: formatDate(workout['workoutDate']),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: workout['isCompleted'] == true
                        ? AppColors.success.withValues(alpha: 0.2)
                        : workout['isMissed'] == true
                            ? AppColors.error.withValues(alpha: 0.2)
                            : AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workout['isCompleted'] == true
                        ? 'Completed'
                        : workout['isMissed'] == true
                            ? 'Missed'
                            : 'Pending',
                    style: TextStyle(
                      color: workout['isCompleted'] == true
                          ? AppColors.success
                          : workout['isMissed'] == true
                              ? AppColors.error
                              : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (workout['completedExercisesCount'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${workout['completedExercisesCount']} exercises',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (workout['isCompleted'] != true)
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminControllerProvider.notifier).updateWorkoutStatus(
                      workoutId: workout['_id'] as String,
                      isCompleted: true,
                    );
                await onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout marked as completed'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Mark Completed'),
          ),
        if (workout['isMissed'] != true && workout['isCompleted'] != true)
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminControllerProvider.notifier).updateWorkoutStatus(
                      workoutId: workout['_id'] as String,
                      isMissed: true,
                    );
                await onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout marked as missed'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.cancel_rounded, size: 18),
            label: const Text('Mark Missed'),
          ),
        TextButton.icon(
          onPressed: () async {
            debugPrint('[WorkoutDetailsModal] Delete button clicked');
            final workoutId = workout['_id'] as String?;
            debugPrint('[WorkoutDetailsModal] Workout ID: $workoutId');
            
            if (workoutId == null) {
              debugPrint('[WorkoutDetailsModal] ERROR: Workout ID is null!');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Workout ID is missing'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
              return;
            }

            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Delete Workout'),
                content: const Text('Are you sure you want to delete this workout? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      debugPrint('[WorkoutDetailsModal] Delete cancelled');
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      debugPrint('[WorkoutDetailsModal] Delete confirmed');
                      Navigator.pop(dialogContext, true);
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            
            debugPrint('[WorkoutDetailsModal] Confirmation result: $confirmed');
            
            if (confirmed == true) {
              // Get root navigator BEFORE closing modal
              final rootNavigator = Navigator.of(context, rootNavigator: true);
              
              // Close details modal first
              Navigator.pop(context);
              
              debugPrint('[WorkoutDetailsModal] Starting delete process for workout: $workoutId');
              
              // Show loading dialog using root navigator context
              final loadingContext = rootNavigator.context;
              showDialog(
                context: loadingContext,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(
                        'Deleting workout...',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );

              try {
                debugPrint('[WorkoutDetailsModal] Calling deleteWorkout with ID: $workoutId');
                await ref.read(adminControllerProvider.notifier).deleteWorkout(workoutId);
                debugPrint('[WorkoutDetailsModal] Delete successful, refreshing...');
                await onRefresh();
                
                // Close loading dialog using root navigator
                rootNavigator.pop();
                
                // Show success message using root context
                if (loadingContext.mounted) {
                  ScaffoldMessenger.of(loadingContext).showSnackBar(
                    const SnackBar(
                      content: Text('Workout deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e, stackTrace) {
                debugPrint('[WorkoutDetailsModal] ERROR deleting workout: $e');
                debugPrint('[WorkoutDetailsModal] Stack trace: $stackTrace');
                
                // Close loading dialog
                rootNavigator.pop();
                
                // Show error message
                if (loadingContext.mounted) {
                  ScaffoldMessenger.of(loadingContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            } else {
              debugPrint('[WorkoutDetailsModal] Delete cancelled');
            }
          },
          icon: const Icon(Icons.delete_rounded, size: 18),
          label: const Text('Delete'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

