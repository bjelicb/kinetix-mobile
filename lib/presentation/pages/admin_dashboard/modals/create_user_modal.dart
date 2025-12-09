import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';

Future<void> showCreateUserModal({
  required BuildContext context,
  required WidgetRef ref,
  required Future<void> Function() onUserCreated,
}) async {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        String selectedRole = 'CLIENT';
        
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
                  'Create New User',
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
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: AppColors.surface1,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
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
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                NeonButton(
                  text: 'Create User',
                  icon: Icons.person_add_rounded,
                  onPressed: () async {
                    try {
                      await ref.read(adminControllerProvider.notifier).createUser(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            role: selectedRole,
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await onUserCreated();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User created successfully'),
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
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

