import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/workout.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../widgets/calendar/calendar_table_widget.dart';
import '../widgets/calendar/selected_day_workouts_widget.dart';
import '../widgets/calendar/schedule_workout_bottom_sheet.dart';
import '../widgets/calendar/select_existing_workout_dialog.dart';
import '../widgets/calendar/calendar_delete_workout_dialog.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  void _handleScheduleWorkout() {
    ScheduleWorkoutBottomSheet.show(
      context: context,
      selectedDay: _selectedDay,
      onCreateNew: () {
        context.push('/workout/new', extra: _selectedDay);
      },
      onSelectExisting: () {
        _handleSelectExistingWorkout();
      },
    );
  }

  void _handleSelectExistingWorkout() {
    final workoutsState = ref.read(workoutControllerProvider);
    workoutsState.whenData((workouts) {
      SelectExistingWorkoutDialog.show(
        context: context,
        ref: ref,
        selectedDay: _selectedDay,
        workouts: workouts,
        onWorkoutSelected: (workout) async {
          await _updateWorkoutDate(workout);
        },
      );
    });
  }

  Future<void> _updateWorkoutDate(Workout workout) async {
    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: _selectedDay,
      isCompleted: workout.isCompleted,
      exercises: workout.exercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout scheduled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleWorkoutTap(Workout workout) {
    context.go('/workout/${workout.id}');
  }

  void _handleDeleteWorkout(String workoutId) {
    CalendarDeleteWorkoutDialog.show(
      context: context,
      ref: ref,
      workoutId: workoutId,
      onDelete: (_) {
        // Deletion handled in dialog
      },
    );
  }

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
                Flexible(
                  flex: _calendarFormat == CalendarFormat.month ? 2 : 1,
                  child: CalendarTableWidget(
                    workouts: workouts,
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    calendarFormat: _calendarFormat,
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
                Expanded(
                  child: SelectedDayWorkoutsWidget(
                    workouts: workouts,
                    selectedDay: _selectedDay,
                    onScheduleWorkout: _handleScheduleWorkout,
                    onWorkoutTap: _handleWorkoutTap,
                    onDeleteWorkout: _handleDeleteWorkout,
                  ),
                ),
              ],
            ),
            loading: () => ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                ShimmerCard(height: 300),
                SizedBox(height: 16),
                ShimmerCard(height: 150),
              ],
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _handleScheduleWorkout,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Schedule Workout'),
        ),
      ),
    );
  }
}
