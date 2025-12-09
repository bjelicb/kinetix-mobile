import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';

Future<void> showCreatePlanModal({
  required BuildContext context,
  required WidgetRef ref,
  required List<User> trainers,
  required Future<void> Function() onCreated,
}) async {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final weeklyCostController = TextEditingController(text: '0');
  String? selectedDifficulty;
  String? selectedTrainerId;

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
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
              'Create New Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Trainer Selection (Required)
                  DropdownButtonFormField<String>(
                    value: selectedTrainerId,
                    decoration: const InputDecoration(
                      labelText: 'Trainer *',
                      filled: true,
                      fillColor: AppColors.surface1,
                    ),
                    items: trainers.map((trainer) {
                      return DropdownMenuItem(
                        value: trainer.id,
                        child: Text(trainer.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTrainerId = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name *',
                      filled: true,
                      fillColor: AppColors.surface1,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: AppColors.surface1,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      filled: true,
                      fillColor: AppColors.surface1,
                    ),
                    items: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'].map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDifficulty = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: weeklyCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weekly Cost (€)',
                      hintText: '0.00',
                      prefixText: '€ ',
                      filled: true,
                      fillColor: AppColors.surface1,
                      helperText: 'Cost per week for Running Tab system\nYou can enter: 7, 7.00, 25.50, etc.',
                      errorText: weeklyCostController.text.isNotEmpty && 
                                 double.tryParse(weeklyCostController.text.trim()) == null
                          ? 'Invalid format. Use numbers only (e.g., 7, 7.00, 25.50)'
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  NeonButton(
                    text: 'Create Plan',
                    icon: Icons.add_rounded,
                    onPressed: (nameController.text.trim().isEmpty || selectedTrainerId == null)
                        ? null
                        : () async {
                            try {
                              final planData = <String, dynamic>{
                                'name': nameController.text.trim(),
                                'trainerId': selectedTrainerId,
                              };

                              final description = descriptionController.text.trim();
                              if (description.isNotEmpty) {
                                planData['description'] = description;
                              }
                              if (selectedDifficulty != null) {
                                planData['difficulty'] = selectedDifficulty;
                              }
                              
                              // Validate weekly cost format
                              final weeklyCostText = weeklyCostController.text.trim();
                              double? weeklyCost;
                              
                              if (weeklyCostText.isNotEmpty) {
                                // Try parsing as double (supports both "7" and "7.50")
                                weeklyCost = double.tryParse(weeklyCostText);
                                if (weeklyCost == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Invalid format. Please enter a number (e.g., 25.50 or 25)'),
                                        backgroundColor: AppColors.warning,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (weeklyCost < 0) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Weekly cost cannot be negative'),
                                        backgroundColor: AppColors.warning,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (weeklyCost > 0) {
                                  planData['weeklyCost'] = weeklyCost;
                                }
                              } else {
                                // Empty means 0
                                planData['weeklyCost'] = 0.0;
                              }
                              
                              planData['isTemplate'] = false;

                              await ref.read(adminControllerProvider.notifier).createPlan(planData);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await onCreated();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Plan created successfully'),
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
          ],
        ),
      ),
    ),
  );
}

