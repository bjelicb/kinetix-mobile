import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';

Future<void> showEditPlanModal({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> plan,
  required Future<void> Function() onUpdated,
}) async {
  final planId = plan['_id'] as String?;
  if (planId == null) return;

  final nameController = TextEditingController(text: plan['name']?.toString() ?? '');
  final descriptionController = TextEditingController(text: plan['description']?.toString() ?? '');
  String? selectedDifficulty = plan['difficulty']?.toString();

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
              'Edit Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            StatefulBuilder(
              builder: (context, setState) {
                final isButtonEnabled = nameController.text.trim().isNotEmpty;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: AppSpacing.lg),
                    NeonButton(
                      text: 'Update Plan',
                      icon: Icons.save_rounded,
                      onPressed: isButtonEnabled
                          ? () async {
                              developer.log('EditPlanModal: Update button clicked', name: 'EditPlanModal');
                              developer.log('EditPlanModal: planId=$planId', name: 'EditPlanModal');
                              developer.log('EditPlanModal: name=${nameController.text.trim()}', name: 'EditPlanModal');
                              developer.log('EditPlanModal: description=${descriptionController.text.trim()}', name: 'EditPlanModal');
                              developer.log('EditPlanModal: difficulty=$selectedDifficulty', name: 'EditPlanModal');
                              
                              try {
                                final planData = <String, dynamic>{
                                  'name': nameController.text.trim(),
                                  'description': descriptionController.text.trim().isEmpty
                                      ? ''
                                      : descriptionController.text.trim(),
                                };
                                if (selectedDifficulty != null) {
                                  planData['difficulty'] = selectedDifficulty;
                                }

                                developer.log('EditPlanModal: Calling updatePlan with data: $planData', name: 'EditPlanModal');
                                await ref.read(adminControllerProvider.notifier).updatePlan(planId, planData);
                                developer.log('EditPlanModal: updatePlan completed successfully', name: 'EditPlanModal');
                                
                                if (!context.mounted) {
                                  developer.log('EditPlanModal: Context not mounted after update', name: 'EditPlanModal');
                                  return;
                                }
                                Navigator.pop(context);
                                await onUpdated();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Plan updated successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e, stackTrace) {
                                developer.log('EditPlanModal: Error updating plan: $e', name: 'EditPlanModal', error: e, stackTrace: stackTrace);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

