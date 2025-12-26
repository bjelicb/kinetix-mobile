import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/workout.dart';
import '../../pages/calendar/utils/calendar_utils.dart';
import '../../controllers/plan_controller.dart';
import '../unlock_button.dart';
import 'calendar_workout_item_widget.dart';

/// Selected day workouts widget showing list or empty state
class SelectedDayWorkoutsWidget extends ConsumerWidget {
  final List<Workout> workouts;
  final DateTime selectedDay;
  final String? currentPlanId;
  final DateTime? lastUnlockedDay;
  final Function(Workout) onWorkoutTap;

  const SelectedDayWorkoutsWidget({
    super.key,
    required this.workouts,
    required this.selectedDay,
    required this.currentPlanId,
    this.lastUnlockedDay,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayWorkouts = CalendarUtils.getWorkoutsForDate(workouts, selectedDay);
    final selectedDateOnly = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final currentPlan = ref.watch(currentPlanProvider).valueOrNull;
    
    debugPrint('[SelectedDayWorkouts] build() for ${selectedDay.toIso8601String().split('T')[0]}');
    debugPrint('[SelectedDayWorkouts] → lastUnlockedDay: ${lastUnlockedDay?.toIso8601String().split('T')[0] ?? 'null'}');
    debugPrint('[SelectedDayWorkouts] → currentPlanId: $currentPlanId');
    debugPrint('[SelectedDayWorkouts] → dayWorkouts.length: ${dayWorkouts.length}');
    
    // Check if any workout is from future plan (not unlocked yet)
    final hasFuturePlanWorkout = dayWorkouts.any((workout) => 
      currentPlan != null && 
      currentPlan.planStatus == 'future' &&
      workout.planId == currentPlan.id
    );
    
    // If day has workout from future plan, show locked state
    if (hasFuturePlanWorkout) {
      debugPrint('[SelectedDayWorkouts] → Day has workout from FUTURE plan - showing locked state');
      return _buildLockedDayState(context);
    }
    
    // Check if day is locked (only if lastUnlockedDay is provided and day is after it)
    // If lastUnlockedDay is null, show all workout logs (from all plans)
    final isLocked = lastUnlockedDay != null && selectedDateOnly.isAfter(lastUnlockedDay!);
    
    // If day is locked (future day beyond unlocked plan), show locked state
    if (isLocked) {
      debugPrint('[SelectedDayWorkouts] → Day is LOCKED (after lastUnlockedDay)');
      return _buildLockedDayState(context);
    }
    
    // Check if day has no workout log
    if (dayWorkouts.isEmpty) {
      debugPrint('[SelectedDayWorkouts] → Day has NO workout log');
      return _buildEmptyState(context, selectedDateOnly);
    }
    
    debugPrint('[SelectedDayWorkouts] → Showing workout list (${dayWorkouts.length} workouts)');
    // Normal day with workout log (from any plan - current, previous)
    return _buildWorkoutList(context, dayWorkouts);
  }
  
  Widget _buildLockedDayState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CalendarUtils.formatSelectedDate(selectedDay), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This day is locked',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Complete your current week to unlock next week',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // UNLOCK BUTTON HERE!
                    const UnlockButton(
                      label: 'Unlock This Week',
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isPast = date.isBefore(todayOnly);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CalendarUtils.formatSelectedDate(selectedDay), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPast ? Icons.event_busy_rounded : Icons.schedule_rounded,
                      size: 48,
                      color: isPast
                          ? AppColors.error.withValues(alpha: 0.5)
                          : AppColors.warning.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPast ? 'No workout scheduled' : 'No plan yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        isPast
                            ? 'This was a rest day or not part of your plan'
                            : 'Your trainer hasn\'t created a plan for this week yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutList(BuildContext context, List<Workout> dayWorkouts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CalendarUtils.formatSelectedDate(selectedDay), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: dayWorkouts.length,
              itemBuilder: (context, index) {
                final workout = dayWorkouts[index];
                return CalendarWorkoutItem(
                  workout: workout,
                  onTap: () => onWorkoutTap(workout),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
