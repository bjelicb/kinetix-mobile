import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../widgets/custom_toggle.dart';
import 'edit_user_modal.dart';

Future<void> showUserDetailsModal({
  required BuildContext context,
  required WidgetRef ref,
  required User user,
  required Future<void> Function() onRefresh,
}) async {
  bool currentStatus = user.isActive;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Role: ${user.role}'),
            if (user.trainerName != null && user.trainerName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Trainer: ${user.trainerName}'),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentStatus
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentStatus ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: currentStatus ? AppColors.success : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (user.role != 'ADMIN')
                      CustomToggle(
                        value: currentStatus,
                        onChanged: (value) async {
                          setDialogState(() => currentStatus = value);
                          try {
                            await ref.read(adminControllerProvider.notifier).updateUserStatus(
                                  userId: user.id,
                                  isActive: value,
                                );
                            await onRefresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value ? 'User activated successfully' : 'User deactivated successfully',
                                  ),
                                  backgroundColor: value ? AppColors.success : AppColors.error,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => currentStatus = !value);
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
                      ),
                  ],
                ),
              ],
            ),
            if (user.role == 'ADMIN')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Admin users cannot be deactivated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await showEditUserModal(
                context: context,
                ref: ref,
                user: user,
                onUpdated: onRefresh,
              );
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit'),
          ),
          if (user.role != 'ADMIN')
            TextButton.icon(
              onPressed: () async {
                debugPrint('[UserDetailsModal] Delete button clicked');
                debugPrint('[UserDetailsModal] User ID: ${user.id}');
                
                // Get root navigator BEFORE closing modal
                final rootNavigator = Navigator.of(context, rootNavigator: true);
                
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Delete User'),
                    content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          debugPrint('[UserDetailsModal] Delete cancelled');
                          Navigator.pop(dialogContext, false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          debugPrint('[UserDetailsModal] Delete confirmed');
                          Navigator.pop(dialogContext, true);
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                debugPrint('[UserDetailsModal] Confirmation result: $confirmed');
                
                if (confirmed == true) {
                  // Close details modal first
                  Navigator.pop(context);
                  
                  debugPrint('[UserDetailsModal] Starting delete process for user: ${user.id}');
                  
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
                            'Deleting user...',
                            style: Theme.of(dialogContext).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );

                  try {
                    debugPrint('[UserDetailsModal] Calling deleteUser with ID: ${user.id}');
                    await ref.read(adminControllerProvider.notifier).deleteUser(user.id);
                    debugPrint('[UserDetailsModal] Delete successful, refreshing...');
                    await onRefresh();
                    
                    // Close loading dialog
                    rootNavigator.pop();
                    
                    // Show success message
                    if (loadingContext.mounted) {
                      ScaffoldMessenger.of(loadingContext).showSnackBar(
                        const SnackBar(
                          content: Text('User deleted successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    debugPrint('[UserDetailsModal] ERROR deleting user: $e');
                    debugPrint('[UserDetailsModal] Stack trace: $stackTrace');
                    
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
                  debugPrint('[UserDetailsModal] Delete cancelled');
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
    ),
  );
}

