import 'package:isar/isar.dart';
import 'exercise_collection.dart';

part 'workout_collection.g.dart';

@collection
class WorkoutCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String name;
  String? planId; // Weekly plan ID (from backend: weeklyPlanId)
  late DateTime scheduledDate;
  int? dayOfWeek; // Plan day index (1-7) - pozicija u planu, NE calendar weekday
  late bool isCompleted;
  late bool isMissed;
  late bool isRestDay;

  // Relations
  final exercises = IsarLinks<ExerciseCollection>();

  // Sync Meta
  late bool isDirty; // True if modified locally and needs sync
  late bool isSyncing; // NOVO: Lock flag to prevent race conditions (dupli push scenario)
  late DateTime updatedAt;

  WorkoutCollection();

  WorkoutCollection.fromJson(Map<String, dynamic> json)
    : serverId = json['serverId'] as String? ?? '',
      name = json['name'] as String,
      scheduledDate = DateTime.parse(json['scheduledDate'] as String),
      dayOfWeek = json['dayOfWeek'] as int?,
      isCompleted = json['isCompleted'] as bool? ?? false,
      isMissed = json['isMissed'] as bool? ?? false,
      isRestDay = json['isRestDay'] as bool? ?? false,
      isDirty = json['isDirty'] as bool? ?? false,
      isSyncing = json['isSyncing'] as bool? ?? false,
      updatedAt = json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now();

  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'name': name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'dayOfWeek': dayOfWeek,
    'isCompleted': isCompleted,
    'isMissed': isMissed,
    'isRestDay': isRestDay,
    'isDirty': isDirty,
    'isSyncing': isSyncing,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
