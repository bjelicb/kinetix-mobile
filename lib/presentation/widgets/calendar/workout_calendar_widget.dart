import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../domain/entities/workout.dart';
import '../../../domain/entities/exercise.dart';
import '../../../data/datasources/local_data_source.dart';
import '../gradient_card.dart';

/// Event marker colors based on workout status
enum WorkoutStatus {
  completed,  // Green
  missed,     // Red
  pending,    // Orange
  rest,       // Gray
}

class WorkoutCalendarWidget extends ConsumerStatefulWidget {
  const WorkoutCalendarWidget({super.key});

  @override
  ConsumerState<WorkoutCalendarWidget> createState() => _WorkoutCalendarWidgetState();
}

class _WorkoutCalendarWidgetState extends ConsumerState<WorkoutCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Workout>> _workoutsByDate = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    
    final month = _focusedDay.month;
    final year = _focusedDay.year;
    
    debugPrint('[Calendar:Load] Loading workouts for month: $month/$year');
    
    try {
      // Load workouts from local DB
      final localDataSource = LocalDataSource();
      final allWorkouts = await localDataSource.getWorkouts();
      
      // Convert WorkoutCollection to Workout entities
      final workouts = <Workout>[];
      for (final workoutCol in allWorkouts) {
        final exercises = await localDataSource.getExercisesForWorkout(workoutCol.id);
        
        // Manual conversion since fromCollection doesn't exist
        final workout = Workout(
          id: workoutCol.serverId,
          name: workoutCol.name,
          scheduledDate: workoutCol.scheduledDate,
          isCompleted: workoutCol.isCompleted,
          exercises: exercises.map((e) {
            return Exercise(
              id: e.id.toString(),
              name: e.name,
              targetMuscle: 'Unknown',
              sets: e.sets.map((s) => WorkoutSet(
                id: s.id,
                weight: s.weight,
                reps: s.reps,
                rpe: s.rpe,
                isCompleted: s.isCompleted,
              )).toList(),
            );
          }).toList(),
          isDirty: workoutCol.isDirty,
          updatedAt: workoutCol.updatedAt,
        );
        
        workouts.add(workout);
      }
      
      // Filter workouts for the selected month
      final monthWorkouts = workouts.where((workout) {
        return workout.scheduledDate.year == year && workout.scheduledDate.month == month;
      }).toList();
      
      // Group workouts by date
      _workoutsByDate = {};
      for (final workout in monthWorkouts) {
        final normalizedDate = DateTime(
          workout.scheduledDate.year,
          workout.scheduledDate.month,
          workout.scheduledDate.day,
        );
        
        if (_workoutsByDate.containsKey(normalizedDate)) {
          _workoutsByDate[normalizedDate]!.add(workout);
        } else {
          _workoutsByDate[normalizedDate] = [workout];
        }
      }
      
      debugPrint('[Calendar:Load] ✓ Loaded ${_workoutsByDate.length} days with workouts (${monthWorkouts.length} total workouts)');
      
    } catch (e) {
      debugPrint('[Calendar:Load] ✗ Error loading workouts: $e');
      _workoutsByDate = {};
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Workout> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _workoutsByDate[normalizedDate] ?? [];
  }

  WorkoutStatus _getWorkoutStatus(Workout workout, DateTime day) {
    if (workout.isCompleted) {
      return WorkoutStatus.completed;
    }
    final now = DateTime.now();
    final dayDate = DateTime(day.year, day.month, day.day);
    
    if (dayDate.isBefore(now)) {
      return WorkoutStatus.missed;
    }
    return WorkoutStatus.pending;
  }

  Color _getStatusColor(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.completed:
        return AppColors.success;
      case WorkoutStatus.missed:
        return AppColors.error;
      case WorkoutStatus.pending:
        return AppColors.warning;
      case WorkoutStatus.rest:
        return AppColors.textSecondary;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      
      final workouts = _getEventsForDay(selectedDay);
      if (workouts.isNotEmpty) {
        AppHaptic.selection();
        // Navigate to workout runner page for the first workout of the day
        final workout = workouts.first;
        context.push('/workout/${workout.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar Grid (includes header)
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildCalendarGrid(),
          
          const SizedBox(height: 16),
          
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return TableCalendar<Workout>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          
          final workout = events.first;
          final status = _getWorkoutStatus(workout, date);
          
          return Positioned(
            bottom: 1,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _loadWorkouts();
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Completed', AppColors.success),
        _buildLegendItem('Missed', AppColors.error),
        _buildLegendItem('Pending', AppColors.warning),
        _buildLegendItem('Rest', AppColors.textSecondary),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

