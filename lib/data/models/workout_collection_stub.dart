// Stub file for web platform - Isar doesn't work on web
class WorkoutCollection {
  int id = 0; // Match Isar Id type
  String serverId = '';
  String name = '';
  DateTime scheduledDate = DateTime.now();
  bool isCompleted = false;
  bool isMissed = false;
  bool isRestDay = false;
  bool isDirty = false;
  DateTime updatedAt = DateTime.now();

  WorkoutCollection();

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

class WorkoutCollectionSchema {
  // Stub for web
}
