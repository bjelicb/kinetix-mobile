import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/workout.dart';
import '../../presentation/controllers/calendar_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/calendar/calendar_table_widget.dart';
import '../widgets/calendar/selected_day_workouts_widget.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  void _handleWorkoutTap(Workout workout) {
    context.push('/workout/${workout.id}/details');
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarDataProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: calendarState.when(
            data: (calendarData) {
              // Pass lastUnlockedDay directly (null means show all workout logs without unlock logic)
              final lastUnlocked = calendarData.lastUnlockedDay;
              
              return Column(
              children: [
                Flexible(
                  flex: _calendarFormat == CalendarFormat.month ? 2 : 1,
                  child: CalendarTableWidget(
                      workouts: calendarData.workouts,
                      currentPlanId: calendarData.currentPlanId,
                      lastUnlockedDay: lastUnlocked,
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
                      workouts: calendarData.workouts,
                    selectedDay: _selectedDay,
                      currentPlanId: calendarData.currentPlanId,
                      lastUnlockedDay: lastUnlocked,
                    onWorkoutTap: _handleWorkoutTap,
                  ),
                ),
              ],
              );
            },
            loading: () => ListView(
              padding: const EdgeInsets.all(20),
              children: const [ShimmerCard(height: 300), SizedBox(height: 16), ShimmerCard(height: 150)],
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: $error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
