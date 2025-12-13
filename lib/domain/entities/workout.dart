import 'exercise.dart';

class Workout {
  final String id;
  final String? serverId;
  final String name;
  final DateTime scheduledDate;
  final bool isCompleted;
  final bool isMissed;
  final bool isRestDay;
  final List<Exercise> exercises;
  final bool isDirty;
  final DateTime updatedAt;

  Workout({
    required this.id,
    this.serverId,
    required this.name,
    required this.scheduledDate,
    required this.isCompleted,
    required this.isMissed,
    required this.isRestDay,
    required this.exercises,
    required this.isDirty,
    required this.updatedAt,
  });
}
