import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';
import '../../../../services/sync_manager.dart';
import '../../../../data/datasources/local_data_source.dart';
import '../../../../data/datasources/remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> showUnassignPlanModal({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> plan,
  required List<User> allClients,
  required Future<void> Function() onUnassigned,
  Future<void> Function()? onRefreshWorkouts,
}) async {
  final planId = plan['_id'] as String?;
  if (planId == null) return;

developer.log('═══════════════════════════════════════════════════════════', name: 'UnassignPlanModal');
developer.log('[UnassignPlanModal] START - Plan ID: $planId', name: 'UnassignPlanModal');

  // Load plan details to get assignedClientIds
  Map<String, dynamic>? planDetails;
  try {
    planDetails = await ref.read(adminControllerProvider.notifier).getPlanById(planId);
    developer.log('[UnassignPlanModal] Plan details loaded successfully', name: 'UnassignPlanModal');
  } catch (e) {
    developer.log('[UnassignPlanModal] ERROR loading plan details: $e', name: 'UnassignPlanModal', error: e);
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
  final assignedClientProfileIds = <String>{};
  final assignedIds = planDetails['assignedClientIds'];
  developer.log('[UnassignPlanModal] assignedClientIds from plan: $assignedIds', name: 'UnassignPlanModal');
  developer.log('[UnassignPlanModal] assignedClientIds type: ${assignedIds.runtimeType}', name: 'UnassignPlanModal');

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
        developer.log('[UnassignPlanModal] Added assignedClientProfileId: $idString', name: 'UnassignPlanModal');
      }
    }
  }

  developer.log('[UnassignPlanModal] Total assignedClientProfileIds: ${assignedClientProfileIds.length}', name: 'UnassignPlanModal');
  developer.log('[UnassignPlanModal] assignedClientProfileIds: $assignedClientProfileIds', name: 'UnassignPlanModal');

  // Map assigned client profile IDs to user IDs - only show assigned clients
  final assignedUserIds = <String>{};
  final assignedClientsList = <User>[];
  
  for (final client in allClients) {
    final clientProfileId = client.clientProfileId ?? client.id;
    developer.log(
      '[UnassignPlanModal] Checking client ${client.name} (id: ${client.id}, clientProfileId: $clientProfileId)',
      name: 'UnassignPlanModal',
    );

    if (assignedClientProfileIds.contains(clientProfileId)) {
      assignedUserIds.add(client.id);
      assignedClientsList.add(client);
      developer.log('[UnassignPlanModal] Matched! Client ${client.name} is assigned (userId: ${client.id})', name: 'UnassignPlanModal');
    }
  }

  developer.log('[UnassignPlanModal] Total assignedUserIds: ${assignedUserIds.length}', name: 'UnassignPlanModal');
  developer.log('[UnassignPlanModal] assignedUserIds: $assignedUserIds', name: 'UnassignPlanModal');
  developer.log('[UnassignPlanModal] assignedClientsList: ${assignedClientsList.length} clients', name: 'UnassignPlanModal');

  if (assignedClientsList.isEmpty) {
    developer.log('[UnassignPlanModal] No assigned clients found - showing message', name: 'UnassignPlanModal');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clients are currently assigned to this plan.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
    return;
  }

  // Pre-select all assigned clients (user can deselect to unassign)
  final selectedClients = <String>{...assignedUserIds};
  developer.log('[UnassignPlanModal] Pre-selected clients: ${selectedClients.length}', name: 'UnassignPlanModal');
  final searchController = TextEditingController();

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      final mediaQuery = MediaQuery.maybeOf(context);
      final bottomPadding = mediaQuery?.viewInsets.bottom ?? 0.0;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            developer.log(
              '[UnassignPlanModal] Builder called - selectedClients: ${selectedClients.length}, assignedUserIds: ${assignedUserIds.length}',
              name: 'UnassignPlanModal',
            );

            final filteredClients = searchController.text.isEmpty
                ? assignedClientsList
                : assignedClientsList.where((client) {
                    final query = searchController.text.toLowerCase();
                    return client.name.toLowerCase().contains(query) || client.email.toLowerCase().contains(query);
                  }).toList();

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Unassign Plan from Clients', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Select clients to unassign from this plan. Uncompleted workout logs and penalties will be removed.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Clients to Unassign:', style: Theme.of(context).textTheme.titleMedium),
                      if (selectedClients.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedClients.length} selected',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                              searchController.text.isEmpty ? 'No assigned clients' : 'No clients found',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = filteredClients[index];
                              final isSelected = selectedClients.contains(client.id);

                              return InkWell(
                                onTap: () {
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
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
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
                                            Text(
                                              client.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              client.email,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppColors.textSecondary,
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
                    text: 'Unassign Plan',
                    icon: Icons.link_off_rounded,
                    onPressed: selectedClients.isEmpty
                        ? null
                        : () async {
                            try {
                              developer.log('═══════════════════════════════════════════════════════════', name: 'UnassignPlanModal');
                              developer.log('[UnassignPlanModal] Unassign button pressed', name: 'UnassignPlanModal');
                              developer.log('[UnassignPlanModal] Selected clients to unassign: ${selectedClients.length}', name: 'UnassignPlanModal');

                              // Cancel plan for each selected client
                              for (final clientId in selectedClients) {
                                final client = assignedClientsList.firstWhere((c) => c.id == clientId);
                                developer.log('[UnassignPlanModal] Unassigning plan from client: ${client.name} (ID: $clientId)', name: 'UnassignPlanModal');
                                
                                try {
                                  await ref.read(adminControllerProvider.notifier).cancelPlan(planId, clientId);
                                  developer.log('[UnassignPlanModal] ✅ Successfully unassigned plan from ${client.name}', name: 'UnassignPlanModal');
                                } catch (e) {
                                  developer.log('[UnassignPlanModal] ❌ Error unassigning plan from ${client.name}: $e', name: 'UnassignPlanModal', error: e);
                                  // Continue with other clients even if one fails
                                }
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              developer.log('[UnassignPlanModal] 🔄 Syncing workouts after plan unassignment...', name: 'UnassignPlanModal');
                              try {
                                final localDataSource = LocalDataSource();
                                final storage = FlutterSecureStorage();
                                final dio = Dio();
                                final remoteDataSource = RemoteDataSource(dio, storage);
                                final syncManager = SyncManager(localDataSource, remoteDataSource);
                                await syncManager.sync();
                                developer.log('[UnassignPlanModal] ✅ Workouts synced successfully', name: 'UnassignPlanModal');
                              } catch (e) {
                                developer.log('[UnassignPlanModal] ⚠️ Error syncing workouts: $e', name: 'UnassignPlanModal', error: e);
                                // Don't fail the whole operation if sync fails
                              }

                              // Add delay to ensure backend has time to process
                              developer.log('[UnassignPlanModal] ⏳ Waiting 1500ms before refreshing lists...', name: 'UnassignPlanModal');
                              await Future.delayed(const Duration(milliseconds: 1500));
                              developer.log('[UnassignPlanModal] ⏳ Delay completed, proceeding with refresh...', name: 'UnassignPlanModal');

                              // Refresh workout list directly FIRST
                              if (onRefreshWorkouts != null) {
                                developer.log('[UnassignPlanModal] 🔄 Calling onRefreshWorkouts() callback...', name: 'UnassignPlanModal');
                                try {
                                  await onRefreshWorkouts();
                                  developer.log('[UnassignPlanModal] ✅ onRefreshWorkouts() completed successfully', name: 'UnassignPlanModal');
                                } catch (e) {
                                  developer.log('[UnassignPlanModal] ❌ Error in onRefreshWorkouts(): $e', name: 'UnassignPlanModal', error: e);
                                }
                              } else {
                                developer.log('[UnassignPlanModal] ⚠️ onRefreshWorkouts callback is null', name: 'UnassignPlanModal');
                              }

                              // Then call general onUnassigned callback
                              developer.log('[UnassignPlanModal] 🔄 Calling onUnassigned() callback...', name: 'UnassignPlanModal');
                              try {
                                await onUnassigned();
                                developer.log('[UnassignPlanModal] ✅ onUnassigned() callback completed', name: 'UnassignPlanModal');
                              } catch (e) {
                                developer.log('[UnassignPlanModal] ❌ Error in onUnassigned(): $e', name: 'UnassignPlanModal', error: e);
                              }
                              developer.log('═══════════════════════════════════════════════════════════', name: 'UnassignPlanModal');

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Plan unassigned from ${selectedClients.length} client(s). Workout logs and penalties have been removed.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              developer.log('[UnassignPlanModal] ❌ ERROR during unassign process: $e', name: 'UnassignPlanModal', error: e);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error unassigning plan: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
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

