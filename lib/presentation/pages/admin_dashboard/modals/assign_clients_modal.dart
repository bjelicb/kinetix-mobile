import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../controllers/admin_controller.dart';
import '../../../../domain/entities/user.dart';

Future<void> showAssignClientsModal({
  required BuildContext context,
  required WidgetRef ref,
  required List<User> trainers,
  required List<User> allClients,
  required Future<void> Function() onRefresh,
}) async {
  String? selectedTrainerId;
  final selectedClients = <String>{};

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
      child: StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign Clients to Trainer',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selectedTrainerId,
                decoration: const InputDecoration(
                  labelText: 'Select Trainer',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
                items: trainers.map((trainer) {
                  return DropdownMenuItem<String>(
                    value: trainer.id,
                    child: Text('${trainer.name} (${trainer.email})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    selectedTrainerId = value;
                    selectedClients.clear();
                    for (final client in allClients) {
                      if (client.trainerId == value) {
                        selectedClients.add(client.id);
                      }
                    }
                  });
                },
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
              Flexible(
                child: allClients.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No clients available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allClients.length,
                        itemBuilder: (context, index) {
                          final client = allClients[index];
                          final isAssigned = client.trainerName != null && client.trainerName!.isNotEmpty;
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
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          client.email,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        if (isAssigned) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 14,
                                                  color: AppColors.success,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    client.trainerName ?? '',
                                                    style: const TextStyle(
                                                      color: AppColors.success,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
              ElevatedButton.icon(
                onPressed: selectedTrainerId == null
                    ? null
                    : () async {
                        try {
                          final currentlyAssignedClients = allClients
                              .where((client) => client.trainerId == selectedTrainerId)
                              .map((client) => client.id)
                              .toSet();

                          final clientsToUnassign = currentlyAssignedClients.difference(selectedClients);

                          for (final clientId in clientsToUnassign) {
                            await ref.read(adminControllerProvider.notifier).assignClientToTrainer(
                                  clientId: clientId,
                                  trainerId: null,
                                );
                          }

                          for (final clientId in selectedClients) {
                            await ref.read(adminControllerProvider.notifier).assignClientToTrainer(
                                  clientId: clientId,
                                  trainerId: selectedTrainerId!,
                                );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          await onRefresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Clients assigned successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.link_rounded),
                label: const Text('Assign'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

