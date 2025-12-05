import 'exercise.dart';

class Workout {
  final String id;
  final String? serverId;
  final String name;
  final DateTime scheduledDate;
  final bool isCompleted;
  final List<Exercise> exercises;
  final bool isDirty;
  final DateTime updatedAt;
  
  Workout({
    required this.id,
    this.serverId,
    required this.name,
    required this.scheduledDate,
    required this.isCompleted,
    required this.exercises,
    required this.isDirty,
    required this.updatedAt,
  });
}

