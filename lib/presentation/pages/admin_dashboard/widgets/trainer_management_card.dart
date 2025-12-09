import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../core/theme/gradients.dart';
import '../../../../domain/entities/user.dart';
import '../../../widgets/gradient_card.dart';
import '../../../widgets/neon_button.dart';

class TrainerManagementCard extends StatelessWidget {
  final List<User> trainers;
  final List<User> allUsers;
  final List<User> clientsWithoutTrainer;
  final VoidCallback onAssignClients;

  const TrainerManagementCard({
    super.key,
    required this.trainers,
    required this.allUsers,
    required this.clientsWithoutTrainer,
    required this.onAssignClients,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      showCyberBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Trainer Manage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              NeonButton(
                text: 'Assign',
                icon: Icons.link_rounded,
                onPressed: clientsWithoutTrainer.isEmpty ? null : onAssignClients,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (trainers.isEmpty)
            Text(
              'No trainers found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: trainers.length,
                itemBuilder: (context, index) {
                  final trainer = trainers[index];
                  final clientCount = allUsers
                      .where((u) =>
                          u.role == 'CLIENT' &&
                          (u.trainerName == trainer.name || u.trainerName == trainer.id))
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.adminAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              Text(
                                trainer.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            '$clientCount clients',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

