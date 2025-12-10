import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../widgets/custom_toggle.dart';

Future<void> showEditUserModal({
  required BuildContext context,
  required WidgetRef ref,
  required User user,
  required Future<void> Function() onUpdated,
}) async {
  final emailController = TextEditingController(text: user.email);
  final firstNameController = TextEditingController(text: user.name.split(' ').first);
  final lastNameController = TextEditingController(
    text: user.name.split(' ').length > 1 ? user.name.split(' ').skip(1).join(' ') : '',
  );

  // State variables OUTSIDE builder to persist across rebuilds
  String selectedRole = user.role;
  bool isActive = user.isActive;
  bool isSaving = false;

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    filled: true,
                    fillColor: AppColors.surface1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    filled: true,
                    fillColor: AppColors.surface1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: AppColors.surface1,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    filled: true,
                    fillColor: AppColors.surface1,
                  ),
                  items: ['CLIENT', 'TRAINER', 'ADMIN'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: user.role == 'ADMIN'
                      ? null // Disable if editing ADMIN user
                      : (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedRole = value;
                            });
                          }
                        },
                ),
                if (user.role == 'ADMIN')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Admin role cannot be changed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    CustomToggle(
                      value: isActive,
                      onChanged: (value) async {
                        setModalState(() {
                          isActive = value;
                        });
                        
                        // Immediately save (kill switch behavior)
                        try {
                          await ref.read(adminControllerProvider.notifier).updateUserStatus(
                                userId: user.id,
                                isActive: value,
                              );
                          await onUpdated();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value ? 'User activated successfully' : 'User deactivated successfully',
                                ),
                                backgroundColor: value ? AppColors.success : AppColors.error,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          // Rollback on error
                          setModalState(() {
                            isActive = !value;
                          });
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
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() {
                            isSaving = true;
                          });

                          try {
                            // Only save user info (name, email, role) - isActive is saved immediately via toggle
                            await ref.read(adminControllerProvider.notifier).updateUser(
                                  userId: user.id,
                                  firstName: firstNameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  email: emailController.text.trim(),
                                  role: selectedRole,
                                );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            await onUpdated();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User updated successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

