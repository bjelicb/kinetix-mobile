// Stub file for web platform - Isar doesn't work on web
import 'exercise_collection_stub.dart';

// Stub IsarLinks for web - mirrors IsarLinks API
class StubIsarLinks<T> {
  final List<T> _items = [];
  
  Future<void> load() async {}
  Future<void> save() async {}
  
  List<T> toList() => _items.toList();
  
  void add(T value) => _items.add(value);
  void addAll(Iterable<T> values) => _items.addAll(values);
  void clear() => _items.clear();
  bool remove(Object? value) => _items.remove(value);
  
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
}

class WorkoutCollection {
  int id = 0; // Match Isar Id type
  String serverId = '';
  String name = '';
  String? planId; // Weekly plan ID (from backend: weeklyPlanId)
  DateTime scheduledDate = DateTime.now();
  int? dayOfWeek; // Plan day index (1-7) - pozicija u planu, NE calendar weekday
  bool isCompleted = false;
  bool isMissed = false;
  bool isRestDay = false;
  bool isDirty = false;
  bool isSyncing = false; // NOVO: Lock flag to prevent race conditions (dupli push scenario)
  DateTime updatedAt = DateTime.now();
  
  // Stub for IsarLinks relation
  final exercises = StubIsarLinks<ExerciseCollection>();

  WorkoutCollection();

  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'name': name,
    'planId': planId,
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

class WorkoutCollectionSchema {
  // Stub for web
}
