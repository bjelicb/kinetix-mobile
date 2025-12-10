/// Data class for workout day
class WorkoutDayData {
  final int dayOfWeek;
  String name;
  bool isRestDay;
  List<ExerciseData> exercises;
  String? notes;
  
  WorkoutDayData({
    required this.dayOfWeek,
    this.name = '',
    this.isRestDay = false,
    List<ExerciseData>? exercises,
    this.notes,
  }) : exercises = exercises ?? [];
}

/// Data class for exercise
class ExerciseData {
  String name;
  int sets;
  String reps; // Can be "10-12" or "10"
  int restSeconds;
  String? notes;
  String? videoUrl;
  
  ExerciseData({
    this.name = '',
    this.sets = 3,
    this.reps = '10',
    this.restSeconds = 60,
    this.notes,
    this.videoUrl,
  });
}

