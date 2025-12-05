import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/nutrition_summary_card.dart';
import '../../presentation/widgets/client_alerts_card.dart';
import '../../presentation/widgets/appointments_card.dart';
import '../../core/utils/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsState = ref.watch(workoutControllerProvider);
    final authState = ref.watch(authControllerProvider);
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              final user = authState.valueOrNull;
              final isTrainer = user?.role == 'TRAINER';
              
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(workoutControllerProvider);
                },
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    // Premium Header
                    SliverToBoxAdapter(
                      child: _buildHeader(context, user, ref),
                    ),
                    
                    // Quick Stats (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: _buildQuickStats(context),
                      ),
                    
                    // Nutrition Summary (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: NutritionSummaryCard(
                            calories: 1850,
                            protein: 120,
                            carbs: 220,
                            fats: 65,
                          ),
                        ),
                      ),
                    
                    // Today's Mission Card
                    SliverToBoxAdapter(
                      child: _buildTodaysMission(context, workouts, ref),
                    ),
                    
                    // Role-dependent content
                    if (isTrainer)
                      SliverToBoxAdapter(
                        child: _buildTrainerContent(context),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _buildClientContent(context, workouts, ref),
                      ),
                    
                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              );
            },
            loading: () => _buildLoadingState(context),
            error: (error, stack) => _buildErrorState(context, error),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, WidgetRef ref) {
    final greeting = _getGreeting();
    final userName = user?.name ?? 'User';
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      foreground: Paint()
                        ..shader = AppGradients.primary.createShader(
                          const Rect.fromLTWH(0, 0, 200, 70),
                        ),
                    ),
                  ),
                ],
              ),
              // Profile Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Streak Counter
          GradientCard(
            gradient: AppGradients.purplePink,
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7 Day Streak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Keep it up!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(context, '12', 'Workouts\nThis Week', AppGradients.primary),
          const SizedBox(width: 12),
          _buildStatCard(context, '2.4k', 'Total\nVolume (kg)', AppGradients.secondary),
          const SizedBox(width: 12),
          _buildStatCard(context, '85%', 'Completion\nRate', AppGradients.success),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Gradient gradient) {
    return SizedBox(
      width: 100,
      height: 90,
      child: GradientCard(
        gradient: gradient,
        padding: const EdgeInsets.all(10),
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontSize: 10,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMission(BuildContext context, workouts, WidgetRef ref) {
    final todayWorkout = workouts.isNotEmpty ? workouts.first : null;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Mission",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
            if (todayWorkout == null)
              EmptyState(
                icon: Icons.fitness_center_rounded,
                title: 'No workout scheduled',
                message: 'Take a rest day or schedule a workout',
                actionLabel: 'Schedule Workout',
                onAction: () {
                  AppHaptic.selection();
                  context.go('/calendar');
                },
              )
          else
            GradientCard(
              gradient: AppGradients.primary,
              padding: const EdgeInsets.all(20),
              showGlow: true,
              onTap: () {
                AppHaptic.selection();
                context.go('/workout/${todayWorkout.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayWorkout.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(todayWorkout.scheduledDate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (todayWorkout.isCompleted)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NeonButton(
                    text: todayWorkout.isCompleted ? 'View Details' : 'Start Workout',
                    icon: todayWorkout.isCompleted ? Icons.visibility : Icons.play_arrow,
                    onPressed: () {
                      AppHaptic.selection();
                context.go('/workout/${todayWorkout.id}');
                    },
                    gradient: AppGradients.secondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientContent(BuildContext context, workouts, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Workouts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (workouts.isEmpty)
            EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No workouts yet',
              message: 'Start your fitness journey by scheduling your first workout',
              actionLabel: 'Schedule Workout',
              onAction: () {
                AppHaptic.selection();
                context.go('/calendar');
              },
            )
          else
            SizedBox(
              height: workouts.length > 5 ? 400 : null,
              child: ListView.builder(
                shrinkWrap: workouts.length <= 5,
                physics: workouts.length > 5 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: workouts.length > 5 ? 5 : workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GradientCard(
                      gradient: AppGradients.card,
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        AppHaptic.selection();
                        context.go('/workout/${workout.id}');
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: workout.isCompleted
                                  ? AppGradients.success
                                  : AppGradients.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              workout.isCompleted
                                  ? Icons.check_rounded
                                  : Icons.fitness_center_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workout.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(workout.scheduledDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () => _showDeleteDialog(context, workout.id, ref),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
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

  Widget _buildTrainerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientAlertsCard(),
          const SizedBox(height: 20),
          AppointmentsCard(),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ShimmerCard(height: 200),
        const SizedBox(height: 16),
        ShimmerCard(height: 120),
        const SizedBox(height: 16),
        ShimmerCard(height: 120),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showDeleteDialog(BuildContext context, String workoutId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(workoutControllerProvider.notifier).deleteWorkout(workoutId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting workout: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


