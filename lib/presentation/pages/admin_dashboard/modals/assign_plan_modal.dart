import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';

Future<void> showAssignPlanModal({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> plan,
  required List<User> allClients,
  required Future<void> Function() onAssigned,
}) async {
  final planId = plan['_id'] as String?;
  if (planId == null) return;

  // Load plan details to get assignedClientIds
  Map<String, dynamic>? planDetails;
  try {
    planDetails = await ref.read(adminControllerProvider.notifier).getPlanById(planId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading plan details: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return;
  }

  // Extract assigned client profile IDs from plan details
  // Backend returns assignedClientIds which can be:
  // - String IDs: "507f1f77bcf86cd799439011"
  // - Populated objects: { _id: "507f1f77bcf86cd799439011", userId: {...} }
  final assignedClientProfileIds = <String>{};
  final assignedIds = planDetails['assignedClientIds'];
  developer.log('AssignPlanModal: assignedClientIds from plan: $assignedIds', name: 'AssignPlanModal');
  developer.log('AssignPlanModal: assignedClientIds type: ${assignedIds.runtimeType}', name: 'AssignPlanModal');
  
  if (assignedIds is List) {
    for (final id in assignedIds) {
      String? idString;
      
      // Handle populated object: { _id: ObjectId, userId: ... }
      if (id is Map) {
        idString = id['_id']?.toString() ?? id.toString();
      } else {
        // Handle string ID directly
        idString = id?.toString();
      }
      
      if (idString != null && idString.isNotEmpty) {
        assignedClientProfileIds.add(idString);
        developer.log('AssignPlanModal: Added assignedClientProfileId: $idString', name: 'AssignPlanModal');
      }
    }
  }

  developer.log('AssignPlanModal: Total assignedClientProfileIds: ${assignedClientProfileIds.length}', name: 'AssignPlanModal');
  developer.log('AssignPlanModal: assignedClientProfileIds: $assignedClientProfileIds', name: 'AssignPlanModal');

  // Map assigned client profile IDs to user IDs
  final assignedUserIds = <String>{};
  for (final client in allClients) {
    final clientProfileId = client.clientProfileId ?? client.id;
    developer.log('AssignPlanModal: Checking client ${client.name} (id: ${client.id}, clientProfileId: $clientProfileId)', name: 'AssignPlanModal');
    
    if (assignedClientProfileIds.contains(clientProfileId)) {
      assignedUserIds.add(client.id);
      developer.log('AssignPlanModal: Matched! Client ${client.name} is assigned (userId: ${client.id})', name: 'AssignPlanModal');
    }
  }

  developer.log('AssignPlanModal: Total assignedUserIds: ${assignedUserIds.length}', name: 'AssignPlanModal');
  developer.log('AssignPlanModal: assignedUserIds: $assignedUserIds', name: 'AssignPlanModal');

  final selectedClients = <String>{...assignedUserIds}; // Pre-select already assigned clients
  developer.log('AssignPlanModal: Pre-selected clients: ${selectedClients.length}', name: 'AssignPlanModal');
  DateTime? selectedStartDate;
  final searchController = TextEditingController();

  if (!context.mounted) return;
  
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final mediaQuery = MediaQuery.maybeOf(context);
      final bottomPadding = mediaQuery?.viewInsets.bottom ?? 0.0;
      
      return Padding(
        padding: EdgeInsets.only(
          bottom: bottomPadding,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
          // Log current state when builder is called
          developer.log('AssignPlanModal: Builder called - selectedClients: ${selectedClients.length}, assignedUserIds: ${assignedUserIds.length}', name: 'AssignPlanModal');
          
          final filteredClients = searchController.text.isEmpty
              ? allClients
              : allClients.where((client) {
                  final query = searchController.text.toLowerCase();
                  return client.name.toLowerCase().contains(query) ||
                      client.email.toLowerCase().contains(query);
                }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Assign Plan to Clients',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Start Date *',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select when the plan should start for clients',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() {
                        selectedStartDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedStartDate == null
                            ? AppColors.error.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedStartDate == null
                              ? 'Select start date'
                              : '${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: selectedStartDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: selectedStartDate == null ? AppColors.textSecondary : AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Clients:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (selectedClients.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${selectedClients.length} selected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clients by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: filteredClients.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            searchController.text.isEmpty ? 'No clients available' : 'No clients found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = filteredClients[index];
                            final isSelected = selectedClients.contains(client.id);
                            final isAlreadyAssigned = assignedUserIds.contains(client.id);
                            
                            // Debug log for first client
                            if (index == 0 && isAlreadyAssigned) {
                              developer.log('AssignPlanModal: First assigned client - ${client.name}, isSelected: $isSelected, isAlreadyAssigned: $isAlreadyAssigned', name: 'AssignPlanModal');
                            }

                            return InkWell(
                              onTap: isAlreadyAssigned
                                  ? null // Disable tap for already assigned clients
                                  : () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedClients.remove(client.id);
                                        } else {
                                          selectedClients.add(client.id);
                                        }
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                color: isAlreadyAssigned
                                    ? AppColors.surface1.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: isAlreadyAssigned
                                          ? null // Disable checkbox for already assigned clients
                                          : (value) {
                                              setModalState(() {
                                                if (value == true) {
                                                  selectedClients.add(client.id);
                                                } else {
                                                  selectedClients.remove(client.id);
                                                }
                                              });
                                            },
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  client.name,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: isAlreadyAssigned
                                                            ? AppColors.textSecondary
                                                            : AppColors.textPrimary,
                                                      ),
                                                ),
                                              ),
                                              if (isAlreadyAssigned)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Assigned',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppColors.primary,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            client.email,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: isAlreadyAssigned
                                                      ? AppColors.textSecondary.withValues(alpha: 0.7)
                                                      : AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                NeonButton(
                  text: 'Assign Plan',
                  icon: Icons.link_rounded,
                  onPressed: (selectedClients.isEmpty || selectedStartDate == null)
                      ? null
                      : () async {
                          try {
                            // Always send userId to backend - backend will handle finding/creating client profile
                            final clientIds = selectedClients.map((clientId) {
                              final client = allClients.firstWhere((c) => c.id == clientId);
                              // Backend expects userId, not clientProfileId - it will handle the mapping
                              developer.log('Client ${client.name} -> sending userId: ${client.id}', name: 'AssignPlanModal');
                              return client.id;
                            }).toList();
                            
                            await ref.read(adminControllerProvider.notifier).assignPlanToClients(
                                  planId,
                                  clientIds,
                                  selectedStartDate!,
                                );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            await onAssigned();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Plan assigned successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              String errorMessage = 'Failed to assign plan';
                              String errorDetails = e.toString();
                              
                              // Parse error message for better UX
                              // Backend throws: "Client cannot be assigned a new plan. Current week must be completed first..."
                              if (errorDetails.contains('cannot unlock next week') || 
                                  errorDetails.contains('Current week must be completed') ||
                                  errorDetails.contains('cannot be assigned a new plan') ||
                                  errorDetails.contains('must complete')) {
                                errorMessage = '⚠️ Cannot Assign Plan\n\nOne or more selected clients must complete their current week\'s workouts before being assigned a new plan.\n\nPlease wait until the current week is completed or select different clients.';
                              } else if (errorDetails.contains('Forbidden') || errorDetails.contains('403')) {
                                errorMessage = 'Access denied. You don\'t have permission to assign this plan.';
                              } else if (errorDetails.contains('not found') || errorDetails.contains('404')) {
                                errorMessage = 'Plan or client not found.';
                              } else if (errorDetails.contains('Exception:')) {
                                errorMessage = errorDetails.split('Exception:').last.trim();
                                if (errorMessage.isEmpty) {
                                  errorMessage = 'An error occurred while assigning the plan.';
                                }
                              } else {
                                // Try to extract message from error string
                                errorMessage = errorDetails;
                              }
                              
                              // Show dialog for unlock errors (more visible)
                              if (errorMessage.contains('cannot unlock') || errorMessage.contains('must complete')) {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_rounded, color: AppColors.warning),
                                        SizedBox(width: 8),
                                        Text('Cannot Assign Plan'),
                                      ],
                                    ),
                                    content: Text(
                                      errorMessage.replaceAll('⚠️ ', '').replaceAll('\n\n', '\n'),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '⚠️ Assignment Failed',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          errorMessage,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.warning,
                                    duration: const Duration(seconds: 6),
                                    action: SnackBarAction(
                                      label: 'Dismiss',
                                      textColor: AppColors.textPrimary,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                ),
              ],
            ),
          );
          },
        ),
      );
    },
  );
}

