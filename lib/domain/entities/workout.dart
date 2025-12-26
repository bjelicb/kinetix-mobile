import 'exercise.dart';

class Workout {
  final String id;
  final String? serverId;
  final String name;
  final String? planId; // Weekly plan ID (from backend: weeklyPlanId)
  final DateTime scheduledDate;
  final int? dayOfWeek; // Plan day index (1-7) - pozicija u planu, NE calendar weekday
  // dayOfWeek = 1 znači prvi dan plana, 2 = drugi dan plana, itd.
  // Backend koristi ovo da pronađe workout u WeeklyPlan.workouts array
  final bool isCompleted;
  final bool isMissed;
  final bool isRestDay;
  final List<Exercise> exercises;
  final bool isDirty;
  final bool isSyncing; // NOVO: Lock flag to prevent race conditions (dupli push scenario)
  final DateTime updatedAt;

  Workout({
    required this.id,
    this.serverId,
    required this.name,
    this.planId,
    required this.scheduledDate,
    this.dayOfWeek, // Optional jer postojeći workout-i možda nemaju
    required this.isCompleted,
    required this.isMissed,
    required this.isRestDay,
    required this.exercises,
    required this.isDirty,
    this.isSyncing = false, // NOVO: Default to false
    required this.updatedAt,
  });
}
