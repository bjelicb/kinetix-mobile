// Stub for web platform - Isar doesn't work on web
class PlanCollection {
  int id = 0;
  String planId = '';
  String name = '';
  String difficulty = '';
  String? description;
  String trainerId = '';
  List<WorkoutDayEmbedded> workoutDays = [];
  bool isDirty = false;
  DateTime updatedAt = DateTime.now();
  DateTime? lastSync;
  
  PlanCollection();
  
  PlanCollection.fromJson(Map<String, dynamic> json)
      : planId = json['planId'] as String? ?? '',
        name = json['name'] as String? ?? '',
        difficulty = json['difficulty'] as String? ?? '',
        description = json['description'] as String?,
        trainerId = json['trainerId'] as String? ?? '',
        workoutDays = [],
        isDirty = json['isDirty'] as bool? ?? false,
        updatedAt = DateTime.now(),
        lastSync = null;
  
  Map<String, dynamic> toJson() => {
        'planId': planId,
        'name': name,
        'difficulty': difficulty,
        'description': description,
        'trainerId': trainerId,
        'isDirty': isDirty,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class WorkoutDayEmbedded {
  int dayOfWeek = 1;
  bool isRestDay = false;
  String name = '';
  List<ExerciseEmbedded> exercises = [];
  int estimatedDuration = 60;
  String? notes;
  
  WorkoutDayEmbedded();
  
  WorkoutDayEmbedded.fromJson(Map<String, dynamic> json)
      : dayOfWeek = json['dayOfWeek'] as int? ?? 1,
        isRestDay = json['isRestDay'] as bool? ?? false,
        name = json['name'] as String? ?? '',
        exercises = [],
        estimatedDuration = json['estimatedDuration'] as int? ?? 60,
        notes = json['notes'] as String?;
  
  Map<String, dynamic> toJson() => {};
}

class ExerciseEmbedded {
  String name = '';
  int sets = 0;
  String reps = '';
  int restSeconds = 60;
  String? notes;
  String? videoUrl;
  String? targetMuscle;
  
  ExerciseEmbedded();
  
  ExerciseEmbedded.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String? ?? '',
        sets = json['sets'] as int? ?? 0,
        reps = json['reps']?.toString() ?? '',
        restSeconds = json['restSeconds'] as int? ?? 60,
        notes = json['notes'] as String?,
        videoUrl = json['videoUrl'] as String?,
        targetMuscle = json['targetMuscle'] as String?;
  
  Map<String, dynamic> toJson() => {};
}

// Stub schema for web platform - Isar doesn't work on web
class PlanCollectionSchema {
  // Stub for web
}

