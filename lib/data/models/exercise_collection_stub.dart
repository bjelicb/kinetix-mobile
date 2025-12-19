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
  
  // Plan exercise metadata (from weekly plan) - must match real model
  int? planSets;        // Planned number of sets
  String? planReps;     // Planned reps (can be "10-12")
  int? restSeconds;     // Rest time in seconds
  String? notes;        // Exercise notes
  String? videoUrl;     // Video tutorial URL
  
  ExerciseCollection();
}

class ExerciseCollectionSchema {
  // Stub for web
}
