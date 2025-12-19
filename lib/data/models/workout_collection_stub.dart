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
  DateTime scheduledDate = DateTime.now();
  bool isCompleted = false;
  bool isMissed = false;
  bool isRestDay = false;
  bool isDirty = false;
  DateTime updatedAt = DateTime.now();
  
  // Stub for IsarLinks relation
  final exercises = StubIsarLinks<ExerciseCollection>();

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
