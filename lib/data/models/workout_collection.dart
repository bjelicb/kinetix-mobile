import 'package:isar/isar.dart';
import 'exercise_collection.dart';

part 'workout_collection.g.dart';

@collection
class WorkoutCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String name;
  late DateTime scheduledDate;
  late bool isCompleted;
  late bool isMissed;
  late bool isRestDay;

  // Relations
  final exercises = IsarLinks<ExerciseCollection>();

  // Sync Meta
  late bool isDirty; // True if modified locally and needs sync
  late DateTime updatedAt;

  WorkoutCollection();

  WorkoutCollection.fromJson(Map<String, dynamic> json)
    : serverId = json['serverId'] as String? ?? '',
      name = json['name'] as String,
      scheduledDate = DateTime.parse(json['scheduledDate'] as String),
      isCompleted = json['isCompleted'] as bool? ?? false,
      isMissed = json['isMissed'] as bool? ?? false,
      isRestDay = json['isRestDay'] as bool? ?? false,
      isDirty = json['isDirty'] as bool? ?? false,
      updatedAt = json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now();

  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'name': name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'isCompleted': isCompleted,
    'isMissed': isMissed,
    'isRestDay': isRestDay,
    'isDirty': isDirty,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
