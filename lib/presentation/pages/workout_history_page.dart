import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/search_bar.dart' as kinetix_search;
import '../../presentation/widgets/filter_bottom_sheet.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../domain/entities/workout.dart';

class WorkoutHistoryPage extends ConsumerStatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  ConsumerState<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends ConsumerState<WorkoutHistoryPage> {
  String? _searchQuery;
  FilterOptions _filterOptions = FilterOptions();

  Future<void> _showFilterSheet() async {
    AppHaptic.selection();
    final result = await FilterBottomSheet.show(
      context: context,
      initialFilters: _filterOptions,
      availableMuscleGroups: [], // Can be populated
      availableExercises: [],
    );

    if (result != null) {
      setState(() {
        _filterOptions = result;
      });
    }
  }

  void _showWorkoutDetails(Workout workout) {
    AppHaptic.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildWorkoutDetailsSheet(workout),
    );
  }

  Widget _buildWorkoutDetailsSheet(Workout workout) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  workout.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMMM dd, yyyy').format(workout.scheduledDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildDetailChip(
                      workout.isCompleted ? 'Completed' : 'Pending',
                      workout.isCompleted ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      '${workout.exercises.length} Exercises',
                      AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...workout.exercises.map((exercise) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise.targetMuscle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${exercise.sets.length} sets',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutControllerProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Workout History',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () {
              AppHaptic.light();
              context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              // Apply filters
              final filteredWorkouts = ref
                  .read(workoutControllerProvider.notifier)
                  .filterWorkouts(_searchQuery, _filterOptions.hasActiveFilters ? _filterOptions : null);

              // Sort by date (newest first)
              filteredWorkouts.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: kinetix_search.SearchBar(
                      hintText: 'Search workouts...',
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query.isEmpty ? null : query;
                        });
                      },
                      onFilterTap: _showFilterSheet,
                    ),
                  ),
                  // Workout List
                  Expanded(
                    child: filteredWorkouts.isEmpty
                        ? EmptyState(
                            icon: Icons.fitness_center_rounded,
                            title: 'No workouts found',
                            message: _searchQuery != null || _filterOptions.hasActiveFilters
                                ? 'Try adjusting your search or filters'
                                : 'Start your fitness journey by scheduling your first workout',
                            actionLabel: 'Schedule Workout',
                            onAction: () => context.go('/calendar'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredWorkouts.length,
                            itemBuilder: (context, index) {
                              final workout = filteredWorkouts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GradientCard(
                                  gradient: AppGradients.card,
                                  padding: const EdgeInsets.all(16),
                                  onTap: () => _showWorkoutDetails(workout),
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
                                              DateFormat('MMM dd, yyyy').format(workout.scheduledDate),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppColors.textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${workout.exercises.length} exercises',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
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
              );
            },
            loading: () => const Center(
              child: ShimmerCard(height: 200),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ),
    );
  }
}
