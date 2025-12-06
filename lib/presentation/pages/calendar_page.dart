import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../domain/entities/workout.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../core/utils/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutControllerProvider);
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) => Column(
              children: [
                // Calendar - use Flexible with better flex ratio
                Flexible(
                  flex: _calendarFormat == CalendarFormat.month ? 2 : 1,
                  child: _buildCalendar(context, workouts),
                ),
                
                // Selected Day Workouts
                Expanded(
                  child: _buildSelectedDayWorkouts(context, workouts),
                ),
              ],
            ),
                  loading: () => ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const ShimmerCard(height: 300),
                      const SizedBox(height: 16),
                      const ShimmerCard(height: 150),
                    ],
                  ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showScheduleWorkoutBottomSheet(context, _selectedDay);
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Schedule Workout'),
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, workouts) {
    // Get workouts by date
    final workoutsByDate = <DateTime, List<Workout>>{};
    for (final workout in workouts) {
      final date = DateTime(
        workout.scheduledDate.year,
        workout.scheduledDate.month,
        workout.scheduledDate.day,
      );
      workoutsByDate.putIfAbsent(date, () => []).add(workout);
    }

    // Calculate max height based on screen size and calendar format
    final screenHeight = MediaQuery.of(context).size.height;
    final maxCalendarHeight = _calendarFormat == CalendarFormat.month 
        ? screenHeight * 0.45  // 45% of screen for month view
        : screenHeight * 0.25; // 25% of screen for week view

    return Container(
      margin: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxCalendarHeight,
        ),
        child: GradientCard(
          gradient: AppGradients.card,
          padding: const EdgeInsets.all(16),
          child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: AppColors.textSecondary),
            defaultTextStyle: TextStyle(color: AppColors.textPrimary),
            selectedDecoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
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
            formatButtonTextStyle: const TextStyle(
              color: AppColors.textPrimary,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
            ),
            titleTextStyle: Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AppColors.textPrimary),
            weekendStyle: TextStyle(color: AppColors.textSecondary),
          ),
          eventLoader: (day) {
            final date = DateTime(day.year, day.month, day.day);
            return workoutsByDate[date] ?? [];
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
        ),
      ),
      ),
    );
  }

  Widget _buildSelectedDayWorkouts(BuildContext context, workouts) {
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    
    final dayWorkouts = workouts.where((workout) {
      final workoutDate = DateTime(
        workout.scheduledDate.year,
        workout.scheduledDate.month,
        workout.scheduledDate.day,
      );
      return isSameDay(selectedDate, workoutDate);
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatSelectedDate(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (dayWorkouts.isEmpty)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust padding based on available height
                  final padding = constraints.maxHeight < 200 
                      ? 16.0 
                      : constraints.maxHeight < 300 
                          ? 24.0 
                          : 32.0;
                  
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              gradient: AppGradients.card,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              size: constraints.maxHeight < 200 ? 48 : 64,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: padding),
                          Text(
                            'No workouts scheduled',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to schedule a workout for this day',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: padding),
                          NeonButton(
                            text: 'Schedule Workout',
                            onPressed: () {
                              // TODO: Show add workout dialog
                            },
                            gradient: AppGradients.primary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dayWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = dayWorkouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GradientCard(
                      gradient: workout.isCompleted
                          ? AppGradients.success
                          : AppGradients.card,
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
                                  _formatTime(workout.scheduledDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (workout.isCompleted)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () => _showDeleteDialog(context, workout.id),
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

  String _formatSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    
    if (isSameDay(selected, today)) {
      return 'Today';
    } else if (isSameDay(selected, today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return '${_selectedDay.day} ${_getMonthName(_selectedDay.month)} ${_selectedDay.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  void _showScheduleWorkoutBottomSheet(BuildContext context, DateTime selectedDay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Schedule Workout',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Selected date: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: 'Create New Workout',
              icon: Icons.add_rounded,
              onPressed: () {
                Navigator.pop(context);
                context.push('/workout/new', extra: selectedDay);
              },
              gradient: AppGradients.primary,
            ),
            const SizedBox(height: 12),
            NeonButton(
              text: 'Select Existing Workout',
              icon: Icons.list_rounded,
              onPressed: () {
                Navigator.pop(context);
                _showSelectExistingWorkoutDialog(context, selectedDay);
              },
              gradient: AppGradients.secondary,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  void _showSelectExistingWorkoutDialog(BuildContext context, DateTime selectedDay) {
    final workoutsState = ref.read(workoutControllerProvider);
    workoutsState.whenData((workouts) {
      if (workouts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No workouts available. Create a new one first.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Select Workout'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return ListTile(
                  title: Text(workout.name),
                  subtitle: Text(_formatSelectedDateForWorkout(workout.scheduledDate)),
                  onTap: () async {
                    Navigator.pop(context);
                    // Update workout scheduled date
                    final updatedWorkout = Workout(
                      id: workout.id,
                      serverId: workout.serverId,
                      name: workout.name,
                      scheduledDate: selectedDay,
                      isCompleted: workout.isCompleted,
                      exercises: workout.exercises,
                      isDirty: true,
                      updatedAt: DateTime.now(),
                    );
                    try {
                      await ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Workout scheduled successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error scheduling workout: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    });
  }
  
  String _formatSelectedDateForWorkout(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _showDeleteDialog(BuildContext context, String workoutId) {
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
