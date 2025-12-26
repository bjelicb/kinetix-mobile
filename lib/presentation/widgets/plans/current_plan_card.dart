import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../controllers/plan_controller.dart';
import '../../pages/plan_details_page.dart';
import '../gradient_card.dart';
import '../shimmer_loader.dart';
import '../unlock_button.dart';

class CurrentPlanCard extends ConsumerWidget {
  const CurrentPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlanAsync = ref.watch(currentPlanProvider);
    
    return currentPlanAsync.when(
      data: (plan) {
        if (plan == null) {
          return const SizedBox.shrink();
        }
        
        // Determine if plan can be tapped (not future plan)
        final canTap = plan.planStatus != 'future';
        
        return GradientCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          showGlow: plan.planStatus == 'future', // Show glow for future plan
          pressEffect: canTap, // Only allow press effect if can tap
          onTap: canTap ? () {
            AppHaptic.selection();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlanDetailsPage(planId: plan.id),
              ),
            );
          } : null, // Block tap for future plan
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: plan.planStatus == 'future'
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.primaryEnd.withValues(alpha: 0.2),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      plan.planStatus == 'future' 
                          ? Icons.lock_outline_rounded
                          : Icons.fitness_center_rounded,
                      color: plan.planStatus == 'future'
                          ? AppColors.textPrimary
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.planStatus == 'future'
                              ? 'Future Plan - Unlock'
                              : plan.planStatus == 'previous'
                                  ? 'Previous Plan'
                                  : 'Current Plan',
                          style: TextStyle(
                            color: plan.planStatus == 'future'
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (plan.planStatus == 'future') ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              'Unlock to Start',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ] else if (plan.planStatus == 'previous') ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Not Active',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          plan.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (canTap)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textSecondary,
                      size: 16,
                    )
                  else
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.error.withValues(alpha: 0.7),
                      size: 16,
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Plan info
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Difficulty badge
                  _buildBadge(
                    icon: Icons.speed_rounded,
                    label: plan.difficulty,
                    color: getDifficultyColor(plan.difficulty),
                  ),
                  
                  // Workout days count
                  _buildBadge(
                    icon: Icons.calendar_today_rounded,
                    label: '${plan.workoutDays.length} days',
                    color: AppColors.info,
                  ),
                  
                  // Trainer name badge (if available)
                  if (plan.trainerName != null && plan.trainerName!.isNotEmpty)
                    _buildBadge(
                      icon: Icons.person_rounded,
                      label: plan.trainerName!,
                      color: AppColors.primary,
                    ),
                  
                  // Weekly cost badge (if available)
                  if (plan.weeklyCost != null && plan.weeklyCost! > 0)
                    _buildBadge(
                      icon: Icons.euro_rounded,
                      label: '${plan.weeklyCost!.toStringAsFixed(2)}€/week',
                      color: AppColors.warning,
                    ),
                ],
              ),
              
              // Description if available (hide for future plan)
              if (plan.planStatus != 'future' && plan.description != null && plan.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  plan.description!,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Future plan message
              if (plan.planStatus == 'future') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unlock this plan to start training',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Unlock Button Action (compact mode)
              const SizedBox(height: 16),
              const UnlockButton(compact: true),
            ],
          ),
        );
      },
      loading: () {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerLoader(
            height: 140,
            width: double.infinity,
            borderRadius: 16,
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint('[CurrentPlanCard] ❌ ERROR: $error');
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Color getDifficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        return AppColors.success;
      case 'INTERMEDIATE':
        return AppColors.warning;
      case 'ADVANCED':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}

