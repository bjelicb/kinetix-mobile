import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';
import '../plan_builder_page.dart';

Future<void> showEditPlanModal({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> plan,
  required Future<void> Function() onUpdated,
  List<User>? trainers,
}) async {
  final planId = plan['_id'] as String?;
  if (planId == null) return;

  final nameController = TextEditingController(text: plan['name']?.toString() ?? '');
  final descriptionController = TextEditingController(text: plan['description']?.toString() ?? '');
  final weeklyCostController = TextEditingController(
    text: (plan['weeklyCost'] ?? 0).toString(),
  );
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
                      // ignore: deprecated_member_use
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
                      text: 'Open Plan Builder',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: isButtonEnabled
                          ? () async {
                              // Close modal and open Plan Builder directly
                              // Don't update plan here - Plan Builder will handle it
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              
                              // Load trainers if not provided
                              List<User> trainersList = trainers ?? [];
                              if (trainersList.isEmpty) {
                                try {
                                  trainersList = await ref.read(adminControllerProvider.notifier).getAllUsers()
                                    .then((users) => users.where((u) => u.role == 'TRAINER').toList());
                                } catch (e) {
                                  // Fallback - will handle in Plan Builder
                                }
                              }
                              
                                // Extract trainer ID - simplified logic
                                String? trainerIdString;
                                final trainerIdValue = plan['trainerId'];
                                
                                if (trainerIdValue is Map) {
                                  trainerIdString = trainerIdValue['userId']?.toString() ?? 
                                                   trainerIdValue['_id']?.toString() ?? 
                                                   trainerIdValue['id']?.toString();
                                } else if (trainerIdValue != null) {
                                  trainerIdString = trainerIdValue.toString();
                                }
                                
                                // Extract weekly cost from plan
                                double? planWeeklyCost;
                                final planWeeklyCostValue = plan['weeklyCost'];
                                if (planWeeklyCostValue != null) {
                                  if (planWeeklyCostValue is num) {
                                    planWeeklyCost = planWeeklyCostValue.toDouble();
                                  } else if (planWeeklyCostValue is String) {
                                    planWeeklyCost = double.tryParse(planWeeklyCostValue);
                                  }
                                }
                                
                                // Navigate to Plan Builder with existing plan data
                                if (!context.mounted) return;
                                
                                // Save root context for refresh callback
                                final rootContext = Navigator.of(context, rootNavigator: true).context;
                                
                                final refresh = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlanBuilderPage(
                                      existingPlan: plan, // Pass existing plan for edit mode
                                      trainerId: trainerIdString,
                                      trainers: trainersList,
                                      initialWeeklyCost: planWeeklyCost, // Pass weekly cost explicitly
                                    ),
                                  ),
                                );
                                
                                // Refresh plan list if plan was updated/created
                                if (refresh == true) {
                                  debugPrint('[EditPlanModal] Plan was saved, calling onUpdated callback');
                                  try {
                                    await onUpdated();
                                    debugPrint('[EditPlanModal] onUpdated callback completed');
                                  } catch (e) {
                                    debugPrint('[EditPlanModal] Error in onUpdated callback: $e');
                                  }
                                  
                                  // Show success message using root context
                                  if (rootContext.mounted) {
                                    ScaffoldMessenger.of(rootContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Plan saved successfully'),
                                        backgroundColor: AppColors.success,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  debugPrint('[EditPlanModal] Plan was not saved (refresh=$refresh)');
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

