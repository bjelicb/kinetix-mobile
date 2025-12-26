import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/pages/calendar/utils/calendar_utils.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../presentation/pages/workout/services/workout_state_service.dart';

class WorkoutDetailsPage extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailsPage({super.key, required this.workoutId});

  /// Format rest time from seconds to human-readable string
  static String formatRestTime(int? restSeconds) {
    if (restSeconds == null) return 'No rest';
    if (restSeconds < 60) return '${restSeconds}s';
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }

  /// Format sets x reps for display
  static String formatSetsReps(int? sets, dynamic reps) {
    if (sets == null || reps == null) return 'N/A';
    return '$sets x $reps';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsState = ref.watch(workoutControllerProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () {
              AppHaptic.light();
              context.pop();
            },
          ),
          title: Text('Workout Details', style: Theme.of(context).textTheme.titleLarge),
        ),
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              final workout = workouts.firstWhere(
                (w) => w.id == workoutId,
                orElse: () => workouts.isNotEmpty ? workouts.first : throw Exception('Workout not found'),
              );

              // Handle rest days
              if (workout.isRestDay) {
                return _buildRestDayView(context, ref, workout);
              }

              return _buildWorkoutDetailsView(context, workout);
            },
            loading: () => const Center(child: ShimmerCard(height: 200)),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading workout: $error', style: TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  NeonButton(text: 'Go Back', onPressed: () => context.pop(), icon: Icons.arrow_back_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayView(BuildContext context, WidgetRef ref, Workout workout) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa_rounded, size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 24),
          Text(
            'Rest Day',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            CalendarUtils.formatSelectedDate(workout.scheduledDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Text(
            'Take a well-deserved rest! Your body needs time to recover and grow stronger.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          // Mark as Completed Button
          NeonButton(
            text: workout.isCompleted ? 'Already Completed' : 'Mark as Completed',
            icon: Icons.check_circle_rounded,
            onPressed: workout.isCompleted || workout.isMissed
                ? null
                : () {
                    AppHaptic.medium();
                    _finishRestDayWorkout(context, ref, workout);
                  },
            gradient: AppGradients.primary,
          ),
          const SizedBox(height: 12),
          // Mark as Missed Button
          NeonButton(
            text: workout.isMissed ? 'Already Missed' : 'Mark as Missed',
            icon: Icons.close_rounded,
            onPressed: workout.isCompleted || workout.isMissed
                ? null
                : () {
                    AppHaptic.medium();
                    _markRestDayAsMissed(context, ref, workout);
                  },
            gradient: AppGradients.error,
          ),
        ],
      ),
    );
  }

  Future<void> _finishRestDayWorkout(BuildContext context, WidgetRef ref, Workout workout) async {
    debugPrint('[WorkoutDetailsPage:RestDay] ═══════════════════════════════════════');
    debugPrint('[WorkoutDetailsPage:RestDay] _finishRestDayWorkout() START');
    debugPrint('[WorkoutDetailsPage:RestDay] Workout: ${workout.name} (ID: ${workout.id})');
    
    final confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    try {
      await WorkoutStateService.finishWorkout(
        workout: workout,
        ref: ref,
        context: context,
        confettiController: confettiController,
      );
      
      debugPrint('[WorkoutDetailsPage:RestDay] ✅ Rest day workout finished successfully');
      
      // Refresh workout data
      ref.invalidate(workoutControllerProvider);
    } catch (e, stackTrace) {
      debugPrint('[WorkoutDetailsPage:RestDay] ❌❌❌ ERROR finishing rest day workout ❌❌❌');
      debugPrint('[WorkoutDetailsPage:RestDay] Error: $e');
      debugPrint('[WorkoutDetailsPage:RestDay] StackTrace: $stackTrace');
      // Error dialog is already shown in finishWorkout(), just log here
    } finally {
      confettiController.dispose();
      debugPrint('[WorkoutDetailsPage:RestDay] ═══════════════════════════════════════');
    }
  }

  Future<void> _markRestDayAsMissed(BuildContext context, WidgetRef ref, Workout workout) async {
    debugPrint('[WorkoutDetailsPage:RestDay] ═══════════════════════════════════════');
    debugPrint('[WorkoutDetailsPage:RestDay] _markRestDayAsMissed() START');
    debugPrint('[WorkoutDetailsPage:RestDay] Workout: ${workout.name} (ID: ${workout.id})');
    
    try {
      await WorkoutStateService.markAsMissed(
        workout: workout,
        ref: ref,
        context: context,
      );
      
      debugPrint('[WorkoutDetailsPage:RestDay] ✅ Rest day workout marked as missed successfully');
      
      // Refresh workout data
      ref.invalidate(workoutControllerProvider);
    } catch (e, stackTrace) {
      debugPrint('[WorkoutDetailsPage:RestDay] ❌❌❌ ERROR marking rest day as missed ❌❌❌');
      debugPrint('[WorkoutDetailsPage:RestDay] Error: $e');
      debugPrint('[WorkoutDetailsPage:RestDay] StackTrace: $stackTrace');
      // Error dialog is already shown in markAsMissed(), just log here
    }
    
    debugPrint('[WorkoutDetailsPage:RestDay] ═══════════════════════════════════════');
  }

  Widget _buildWorkoutDetailsView(BuildContext context, Workout workout) {
    return Column(
      children: [
        // Workout Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: GradientCard(
            gradient: AppGradients.card,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      CalendarUtils.formatSelectedDate(workout.scheduledDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (workout.exercises.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${workout.exercises.length} ${workout.exercises.length == 1 ? 'exercise' : 'exercises'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Exercise List
        Expanded(
          child: workout.exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No exercises',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This workout has no exercises yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: workout.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = workout.exercises[index];
                    return _buildExerciseCard(context, exercise, index + 1);
                  },
                ),
        ),

        // Start Workout Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: NeonButton(
            text: 'Start Workout',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              AppHaptic.medium();
              context.push('/workout/$workoutId');
            },
            gradient: AppGradients.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise, int exerciseNumber) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Name and Number
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      '$exerciseNumber',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      if (exercise.targetMuscle != 'Unknown') ...[
                        const SizedBox(height: 4),
                        Text(
                          exercise.targetMuscle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sets x Reps
            _buildInfoRow(
              context,
              Icons.repeat_rounded,
              'Sets x Reps',
              formatSetsReps(exercise.planSets, exercise.planReps),
            ),

            // Rest Time
            if (exercise.restSeconds != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, Icons.timer_rounded, 'Rest Time', formatRestTime(exercise.restSeconds)),
            ],

            // Notes
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, Icons.note_rounded, 'Notes', exercise.notes!, isMultiline: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
