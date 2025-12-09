import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../core/theme/gradients.dart';
import '../../../widgets/cyber_loader.dart';
import '../../../widgets/gradient_card.dart';
import '../../../widgets/neon_button.dart';
// import 'plan_detail_item.dart'; // unused

class PlanManagementCard extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> plans;
  final VoidCallback onCreatePlan;
  final ValueChanged<Map<String, dynamic>> onPlanTap;

  const PlanManagementCard({
    super.key,
    required this.isLoading,
    required this.plans,
    required this.onCreatePlan,
    required this.onPlanTap,
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
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Plan Manage',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              NeonButton(
                text: 'Create',
                icon: Icons.add_rounded,
                onPressed: onCreatePlan,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No plans found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Plans will appear here once trainers create them',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return InkWell(
                    onTap: () => onPlanTap(plan),
                    child: Padding(
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['name'] ?? 'Unnamed Plan',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    'By: ${plan['trainerName'] ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  if (plan['difficulty'] != null)
                                    Text(
                                      'Difficulty: ${plan['difficulty']}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${plan['assignedClientCount'] ?? 0} clients',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
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

