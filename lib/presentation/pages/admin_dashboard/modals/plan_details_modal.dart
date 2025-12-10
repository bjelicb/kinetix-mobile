import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/cyber_loader.dart';
import '../utils/date_formatters.dart';
import '../widgets/plan_detail_item.dart';
import 'assign_plan_modal.dart';
import 'edit_plan_modal.dart';

Future<void> showPlanDetailsModal({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> plan,
  required Future<void> Function() onRefresh,
  required List<User> allClients,
}) async {
  final planId = plan['_id'] as String?;
  if (planId == null) return;

  Map<String, dynamic>? planDetails;
  var isLoading = true;

  try {
    planDetails = await ref.read(adminControllerProvider.notifier).getPlanById(planId);
    isLoading = false;
  } catch (e) {
    isLoading = false;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading plan: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;

  final planData = planDetails;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(planData['name'] ?? 'Plan Details'),
      content: SingleChildScrollView(
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (planData['description'] != null) ...[
                    Text(
                      'Description:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planData['description'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: PlanDetailItem(
                          label: 'Trainer',
                          value: planData['trainerName'] ?? 'Unknown',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PlanDetailItem(
                          label: 'Difficulty',
                          value: planData['difficulty'] ?? 'N/A',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PlanDetailItem(
                    label: 'Weekly Cost',
                    value: '€${(planData['weeklyCost'] ?? 0).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  PlanDetailItem(
                    label: 'Assigned Clients',
                    value: '${planData['assignedClientCount'] ?? planData['assignedClientIds']?.length ?? 0}',
                  ),
                  if (planData['workouts'] != null && (planData['workouts'] as List).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Workouts:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                      const SizedBox(height: 8),
                      ...(planData['workouts'] as List).map<Widget>((workout) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    workout['name']?.toString() ?? 'Unnamed Workout',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                if (workout['dayOfWeek'] != null)
                                  Text(
                                    formatDayOfWeek(workout['dayOfWeek']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await showAssignPlanModal(
              context: context,
              ref: ref,
              plan: plan,
              allClients: allClients,
              onAssigned: onRefresh,
            );
          },
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Assign'),
        ),
        TextButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            // Load trainers for Plan Builder - ensure we get all trainers
            List<User> trainers = [];
            try {
              final allUsers = await ref.read(adminControllerProvider.notifier).getAllUsers();
              trainers = allUsers.where((u) => u.role == 'TRAINER').toList();
              debugPrint('[PlanDetailsModal] Loaded ${trainers.length} trainers for Plan Builder');
              debugPrint('[PlanDetailsModal] Trainer IDs: ${trainers.map((t) => '${t.name} (${t.id})').join(", ")}');
            } catch (e) {
              debugPrint('[PlanDetailsModal] Error loading trainers: $e');
              // Will handle in Plan Builder if needed
            }
            
            if (!context.mounted) return;
            
            // Save root context before showing modal
            final rootContext = Navigator.of(context, rootNavigator: true).context;
            
            await showEditPlanModal(
              context: context,
              ref: ref,
              plan: planData,
              trainers: trainers,
              onUpdated: () async {
                debugPrint('[PlanDetailsModal] onUpdated callback called - refreshing plans...');
                await onRefresh();
                debugPrint('[PlanDetailsModal] Plans refreshed after edit');
              },
            );
            
            // Ensure plans are refreshed even if callback wasn't called
            debugPrint('[PlanDetailsModal] EditPlanModal closed, ensuring plans are refreshed...');
            if (rootContext.mounted) {
              await onRefresh();
            }
          },
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit'),
        ),
        TextButton.icon(
          onPressed: () async {
            debugPrint('[PlanDetailsModal] Duplicate button clicked');
            debugPrint('[PlanDetailsModal] Plan ID: $planId');
            
            // Get root navigator BEFORE closing modal
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Duplicate Plan'),
                content: Text('Create a copy of "${planData['name']}"?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      debugPrint('[PlanDetailsModal] Duplicate cancelled');
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      debugPrint('[PlanDetailsModal] Duplicate confirmed');
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Duplicate'),
                  ),
                ],
              ),
            );
            
            debugPrint('[PlanDetailsModal] Duplicate confirmation result: $confirmed');
            
            if (confirmed == true) {
              // Close details modal first
              if (!context.mounted) return;
              Navigator.pop(context);
              
              debugPrint('[PlanDetailsModal] Starting duplicate process for plan: $planId');
              
              // Save context references before async operations
              final modalContext = context;
              final rootContext = rootNavigator.context;
              
              // Show loading dialog using root navigator context
              if (!modalContext.mounted) return;
              showDialog(
                context: rootContext,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(
                        'Duplicating plan...',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );

              try {
                debugPrint('[PlanDetailsModal] Calling duplicatePlan with ID: $planId');
                await ref.read(adminControllerProvider.notifier).duplicatePlan(planId);
                debugPrint('[PlanDetailsModal] Duplicate successful');
                
                // Close loading dialog first
                if (rootNavigator.canPop()) {
                  rootNavigator.pop();
                }
                
                // Refresh parent list (modal stays open)
                await onRefresh();
                
                // Show success message in modal context
                if (modalContext.mounted) {
                  ScaffoldMessenger.of(modalContext).showSnackBar(
                    const SnackBar(
                      content: Text('Plan duplicated successfully'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                debugPrint('[PlanDetailsModal] ERROR duplicating plan: $e');
                debugPrint('[PlanDetailsModal] Stack trace: $stackTrace');
                
                // Close loading dialog first
                if (rootNavigator.canPop()) {
                  rootNavigator.pop();
                }
                
                // Show error message in modal context
                if (modalContext.mounted) {
                  ScaffoldMessenger.of(modalContext).showSnackBar(
                    SnackBar(
                      content: Text('Error duplicating plan: ${e.toString().replaceAll('Exception: ', '').split('\n').first}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            } else {
              debugPrint('[PlanDetailsModal] Duplicate cancelled');
            }
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Duplicate'),
        ),
        TextButton.icon(
          onPressed: () async {
            debugPrint('[PlanDetailsModal] Delete button clicked');
            debugPrint('[PlanDetailsModal] Plan ID: $planId');
            
            // Get root navigator BEFORE closing modal
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Delete Plan'),
                content: Text('Are you sure you want to delete "${planData['name']}"? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      debugPrint('[PlanDetailsModal] Delete cancelled');
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      debugPrint('[PlanDetailsModal] Delete confirmed');
                      Navigator.pop(dialogContext, true);
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            
            debugPrint('[PlanDetailsModal] Delete confirmation result: $confirmed');
            
            if (confirmed == true) {
              debugPrint('[PlanDetailsModal] Starting delete process for plan: $planId');
              
              // Save context references before async operations
              final modalContext = context;
              final rootContext = rootNavigator.context;
              
              if (!rootContext.mounted) return;
              // Show loading dialog using root navigator context
              showDialog(
                context: rootContext,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(
                        'Deleting plan...',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );

              try {
                debugPrint('[PlanDetailsModal] Calling deletePlan with ID: $planId');
                await ref.read(adminControllerProvider.notifier).deletePlan(planId);
                debugPrint('[PlanDetailsModal] Delete successful');
                
                // Close loading dialog first
                if (rootNavigator.canPop()) {
                  rootNavigator.pop();
                }
                
                // Close modal
                if (modalContext.mounted) {
                  Navigator.pop(modalContext);
                }
                
                // Refresh parent list after modal is closed
                await onRefresh();
                
                // Success message will be shown by parent page if needed
                // No need to show SnackBar here as modal is already closed
                debugPrint('[PlanDetailsModal] Plan deleted and modal closed');
              } catch (e, stackTrace) {
                debugPrint('[PlanDetailsModal] ERROR deleting plan: $e');
                debugPrint('[PlanDetailsModal] Stack trace: $stackTrace');
                
                // Close loading dialog first
                if (rootNavigator.canPop()) {
                  rootNavigator.pop();
                }
                
                // Show error message in modal context (modal still open)
                if (modalContext.mounted) {
                  ScaffoldMessenger.of(modalContext).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting plan: ${e.toString().replaceAll('Exception: ', '').split('\n').first}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            } else {
              debugPrint('[PlanDetailsModal] Delete cancelled');
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

