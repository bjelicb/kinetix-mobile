// Stub file for web platform - Isar doesn't work on web
class WorkoutSet {
  String id = '';
  double weight = 0.0;
  int reps = 0;
  double? rpe;
  bool isCompleted = false;
  
  WorkoutSet();
}

class ExerciseCollection {
  int id = 0; // Match Isar Id type
  String name = '';
  String targetMuscle = '';
  List<WorkoutSet> sets = [];
  
  ExerciseCollection();
}

class ExerciseCollectionSchema {
  // Stub for web
}
