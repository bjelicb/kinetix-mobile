import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../controllers/plan_controller.dart';
import '../../pages/plan_details_page.dart';
import '../gradient_card.dart';
import '../shimmer_loader.dart';

class CurrentPlanCard extends ConsumerWidget {
  const CurrentPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[CurrentPlanCard] build() START');
    final currentPlanAsync = ref.watch(currentPlanProvider);
    debugPrint('[CurrentPlanCard] → currentPlanAsync state: ${currentPlanAsync.runtimeType}');
    debugPrint('[CurrentPlanCard] → hasValue: ${currentPlanAsync.hasValue}');
    debugPrint('[CurrentPlanCard] → isLoading: ${currentPlanAsync.isLoading}');
    debugPrint('[CurrentPlanCard] → hasError: ${currentPlanAsync.hasError}');
    
    return currentPlanAsync.when(
      data: (plan) {
        debugPrint('[CurrentPlanCard] → Provider state: data');
        debugPrint('[CurrentPlanCard] → Plan value: ${plan?.name ?? 'null'}');
        if (plan == null) {
          // Debug: Show message when no plan found
          debugPrint('[CurrentPlanCard] ✗ No plan found - card will not be displayed');
          debugPrint('[CurrentPlanCard] → Returning SizedBox.shrink()');
          debugPrint('═══════════════════════════════════════════════════════════');
          return const SizedBox.shrink();
        }
        
        debugPrint('[CurrentPlanCard] ✓✓✓ Plan found: ${plan.name}');
        debugPrint('[CurrentPlanCard] → Plan ID: ${plan.id}');
        debugPrint('[CurrentPlanCard] → Difficulty: ${plan.difficulty}');
        debugPrint('[CurrentPlanCard] → Workout days: ${plan.workoutDays.length}');
        debugPrint('[CurrentPlanCard] → Description: ${plan.description ?? 'No description'}');
        debugPrint('[CurrentPlanCard] → Rendering card...');
        debugPrint('═══════════════════════════════════════════════════════════');
        
        return GradientCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          showGlow: true,
          pressEffect: true,
          onTap: () {
            AppHaptic.selection();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlanDetailsPage(planId: plan.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primaryEnd.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Plan',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary,
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
                    label: '${plan.workoutDays.where((d) => !d.isRestDay).length} days',
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
              
              // Description if available
              if (plan.description != null && plan.description!.isNotEmpty) ...[
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
            ],
          ),
        );
      },
      loading: () {
        debugPrint('[CurrentPlanCard] → Provider state: loading');
        debugPrint('[CurrentPlanCard] → Showing ShimmerLoader...');
        debugPrint('═══════════════════════════════════════════════════════════');
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
        debugPrint('[CurrentPlanCard] ✗✗✗ Provider state: error');
        debugPrint('[CurrentPlanCard] → Error: $error');
        debugPrint('[CurrentPlanCard] → Stack trace: $stackTrace');
        debugPrint('[CurrentPlanCard] → Returning SizedBox.shrink()');
        debugPrint('═══════════════════════════════════════════════════════════');
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

