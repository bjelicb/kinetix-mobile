import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/workout.dart';
import '../../pages/calendar/utils/calendar_utils.dart';
import '../../pages/calendar/utils/calendar_size_utils.dart';
import '../../controllers/plan_controller.dart';
import '../gradient_card.dart';

/// Calendar table widget with TableCalendar configuration
class CalendarTableWidget extends ConsumerWidget {
  final List<Workout> workouts;
  final String? currentPlanId;
  final DateTime? lastUnlockedDay;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(CalendarFormat format) onFormatChanged;
  final Function(DateTime focusedDay) onPageChanged;

  const CalendarTableWidget({
    super.key,
    required this.workouts,
    required this.currentPlanId,
    required this.lastUnlockedDay,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsByDate = CalendarUtils.groupWorkoutsByDate(workouts);
    final sizes = CalendarSizeUtils.calculateCalendarSizes(context, calendarFormat);
    final currentPlan = ref.watch(currentPlanProvider).valueOrNull;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sizes.maxHeight),
        child: GradientCard(
          gradient: AppGradients.card,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            shouldFillViewport: true,
            rowHeight: sizes.rowHeight,
            daysOfWeekHeight: sizes.daysOfWeekHeight,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
              selectedDecoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              markersMaxCount: 1,
              markerSize: 6,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: sizes.isSmallPhone ? 12 : 14),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
              titleTextStyle: (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
                fontSize: sizes.isSmallPhone ? 18 : null,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textPrimary),
              weekendStyle: TextStyle(color: AppColors.textSecondary),
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, date) {
                final month = CalendarUtils.getMonthName(date.month);
                final year = date.year.toString();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      year,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: sizes.isSmallPhone ? 10 : 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        month,
                        style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                          fontSize: sizes.isSmallPhone ? 16 : 20,
                          color: AppColors.textPrimary,
                        ),
                        softWrap: false,
                      ),
                    ),
                  ],
                );
              },
              markerBuilder: (context, date, events) {
                final dateOnly = DateTime(date.year, date.month, date.day);
                
                if (events.isEmpty) {
                  // No workout log for this day
                  final today = DateTime.now();
                  final todayOnly = DateTime(today.year, today.month, today.day);
                  
                  // Past day without workout = faded marker
                  if (dateOnly.isBefore(todayOnly)) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                }
                
                final workout = events.first as Workout;
                
                // Determine if workout is from future plan (not unlocked yet)
                final isFromFuturePlan = currentPlan != null && 
                                        currentPlan.planStatus == 'future' &&
                                        workout.planId == currentPlan.id;
                
                // If workout is from future plan, always show as LOCKED
                if (isFromFuturePlan) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }
                
                // Determine if workout is from unlocked plan (for unlock logic)
                // Only apply unlock logic if currentPlanId exists and matches workout planId
                final isFromCurrentPlan = currentPlanId != null && 
                                          workout.planId == currentPlanId;
                
                // IMPORTANT: Show workout status for ALL plans (current, previous)
                // If currentPlanId exists and workout is from current plan, apply unlock logic (lastUnlockedDay)
                // If currentPlanId is null OR workout is from previous plan, show status without unlock logic
                // This ensures workout logs from all plans are visible even when there's no currentPlanId
                final status = CalendarUtils.getWorkoutStatus(
                  workout, 
                  date, 
                  null, 
                  (currentPlanId != null && isFromCurrentPlan) ? lastUnlockedDay : null, // Only apply unlock logic for current plan
                );
                
                final color = CalendarUtils.getStatusColor(status);
                
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: status == WorkoutStatus.locked
                          ? Border.all(
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            eventLoader: (day) {
              final date = DateTime(day.year, day.month, day.day);
              return workoutsByDate[date] ?? [];
            },
            onDaySelected: onDaySelected,
            onFormatChanged: onFormatChanged,
            onPageChanged: onPageChanged,
          ),
        ),
      ),
    );
  }
}
