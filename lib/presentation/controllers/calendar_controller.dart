import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/workout.dart';
import 'workout_controller.dart';
import 'auth_controller.dart';
import '../pages/calendar/utils/calendar_utils.dart';

part 'calendar_controller.g.dart';

class CalendarData {
  final List<Workout> workouts;
  final String? currentPlanId;
  final DateTime? lastUnlockedDay;
  
  CalendarData({
    required this.workouts,
    required this.currentPlanId,
    required this.lastUnlockedDay,
  });
}

@riverpod
Future<CalendarData> calendarData(CalendarDataRef ref) async {
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('[CalendarDataProvider] START');
  
  // Watch both providers
  final workouts = await ref.watch(workoutControllerProvider.future);
  final user = await ref.watch(authControllerProvider.future);
  
  debugPrint('[CalendarDataProvider] → Workouts loaded: ${workouts.length}');
  debugPrint('[CalendarDataProvider] → User loaded: ${user?.name}');
  debugPrint('[CalendarDataProvider] → User currentPlanId: ${user?.currentPlanId}');
  
  final currentPlanId = user?.currentPlanId;
  
  // IMPORTANT: Load ALL workout logs (from all plans)
  // Future plan workouts will be displayed as LOCKED in the calendar
  // Do NOT filter them out - they need to be visible but locked
  final lastUnlockedDay = CalendarUtils.getLastUnlockedDay(workouts, currentPlanId);
  
  debugPrint('[CalendarDataProvider] → Calculated lastUnlockedDay: ${lastUnlockedDay?.toIso8601String().split('T')[0]}');
  debugPrint('[CalendarDataProvider] COMPLETE');
  debugPrint('═══════════════════════════════════════════════════════════');
  
  return CalendarData(
    workouts: workouts, // Return ALL workouts (future plans will be shown as locked)
    currentPlanId: currentPlanId,
    lastUnlockedDay: lastUnlockedDay,
  );
}

