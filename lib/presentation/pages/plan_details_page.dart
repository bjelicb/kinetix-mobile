import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_feedback.dart';
import '../controllers/plan_controller.dart';
import '../widgets/gradient_background.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/plans/plan_day_widget.dart';
import '../widgets/unlock_button.dart';

class PlanDetailsPage extends ConsumerWidget {
  final String planId;

  const PlanDetailsPage({
    super.key,
    required this.planId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planByIdProvider(planId));
    final currentPlanAsync = ref.watch(currentPlanProvider);
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              AppHaptic.selection();
              Navigator.of(context).pop();
            },
          ),
          title: planAsync.maybeWhen(
            data: (plan) => plan != null
                ? Text(
                    plan.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            orElse: () => null,
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                AppHaptic.selection();
                _showPlanInfo(context, planAsync.value);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: planAsync.when(
            data: (plan) {
              if (plan == null) {
                return EmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'Plan Not Found',
                  message: 'This plan could not be loaded.',
                );
              }
              
              // Check if this is a future plan (not unlocked)
              final currentPlan = currentPlanAsync.valueOrNull;
              final isFuturePlan = currentPlan != null && 
                                   currentPlan.id == plan.id && 
                                   currentPlan.planStatus == 'future';
              
              // If future plan, show locked message
              if (isFuturePlan) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 64,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'This Plan is Locked',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlock this plan to view details and start training',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const UnlockButton(),
                      ],
                    ),
                  ),
                );
              }
              
              // Sort workout days by dayOfWeek
              final sortedDays = List.from(plan.workoutDays)
                ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
              
              return CustomScrollView(
                slivers: [
                  // Plan header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Difficulty badge + Unlock Button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(plan.difficulty)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getDifficultyColor(plan.difficulty)
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.speed_rounded,
                                      size: 16,
                                      color: _getDifficultyColor(plan.difficulty),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      plan.difficulty,
                                      style: TextStyle(
                                        color: _getDifficultyColor(plan.difficulty),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: UnlockButton(compact: true),
                              ),
                            ],
                          ),
                          
                          // Description if available
                          if (plan.description != null &&
                              plan.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              plan.description!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Stats
                          Row(
                            children: [
                              _buildStat(
                                icon: Icons.calendar_today_rounded,
                                label: 'Workout Days',
                                value: sortedDays
                                    .where((d) => !d.isRestDay)
                                    .length
                                    .toString(),
                              ),
                              const SizedBox(width: 16),
                              _buildStat(
                                icon: Icons.hotel_rounded,
                                label: 'Rest Days',
                                value: sortedDays
                                    .where((d) => d.isRestDay)
                                    .length
                                    .toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Days header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Weekly Schedule',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Days list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final day = sortedDays[index];
                        return PlanDayWidget(workoutDay: day);
                      },
                      childCount: sortedDays.length,
                    ),
                  ),
                  
                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoader(
                  height: 100,
                  width: double.infinity,
                  borderRadius: 16,
                ),
              ),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error Loading Plan',
              message: 'Could not load plan details. Please try again.',
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
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
  
  void _showPlanInfo(BuildContext context, dynamic plan) {
    if (plan == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        title: Text(
          'Plan Information',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', plan.name),
            const SizedBox(height: 8),
            _buildInfoRow('Difficulty', plan.difficulty),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Total Days',
              plan.workoutDays.length.toString(),
            ),
            if (plan.description != null && plan.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Description',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptic.selection();
              Navigator.of(context).pop();
            },
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

