import 'package:isar/isar.dart';

part 'plan_collection.g.dart';

@collection
class PlanCollection {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String planId; // Server ID (ObjectId string)
  
  late String name;
  late String difficulty; // 'BEGINNER', 'INTERMEDIATE', 'ADVANCED'
  String? description;
  late String trainerId;
  
  List<WorkoutDayEmbedded> workoutDays = [];
  
  // Sync meta
  late bool isDirty;
  late DateTime updatedAt;
  DateTime? lastSync;
  
  PlanCollection();
  
  PlanCollection.fromJson(Map<String, dynamic> json)
      : planId = json['planId'] as String,
        name = json['name'] as String,
        difficulty = json['difficulty'] as String,
        description = json['description'] as String?,
        trainerId = json['trainerId'] as String,
        workoutDays = (json['workoutDays'] as List<dynamic>?)
                ?.map((e) => WorkoutDayEmbedded.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isDirty = json['isDirty'] as bool? ?? false,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        lastSync = json['lastSync'] != null
            ? DateTime.parse(json['lastSync'] as String)
            : null;
  
  Map<String, dynamic> toJson() => {
        'planId': planId,
        'name': name,
        'difficulty': difficulty,
        'description': description,
        'trainerId': trainerId,
        'workoutDays': workoutDays.map((e) => e.toJson()).toList(),
        'isDirty': isDirty,
        'updatedAt': updatedAt.toIso8601String(),
        'lastSync': lastSync?.toIso8601String(),
      };
}

@embedded
class WorkoutDayEmbedded {
  late int dayOfWeek; // 1-7 (Monday-Sunday)
  late bool isRestDay;
  late String name;
  List<ExerciseEmbedded> exercises = [];
  late int estimatedDuration; // minutes
  String? notes;
  
  WorkoutDayEmbedded();
  
  WorkoutDayEmbedded.fromJson(Map<String, dynamic> json)
      : dayOfWeek = json['dayOfWeek'] as int,
        isRestDay = json['isRestDay'] as bool? ?? false,
        name = json['name'] as String,
        exercises = (json['exercises'] as List<dynamic>?)
                ?.map((e) => ExerciseEmbedded.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        estimatedDuration = json['estimatedDuration'] as int? ?? 60,
        notes = json['notes'] as String?;
  
  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'isRestDay': isRestDay,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'estimatedDuration': estimatedDuration,
        'notes': notes,
      };
}

@embedded
class ExerciseEmbedded {
  late String name;
  late int sets;
  late String reps; // Can be "10-12" or number string
  late int restSeconds;
  String? notes;
  String? videoUrl;
  String? targetMuscle;
  
  ExerciseEmbedded();
  
  ExerciseEmbedded.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        sets = json['sets'] as int,
        reps = json['reps'].toString(), // Convert to string if number
        restSeconds = json['restSeconds'] as int? ?? 60,
        notes = json['notes'] as String?,
        videoUrl = json['videoUrl'] as String?,
        targetMuscle = json['targetMuscle'] as String?;
  
  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
        'notes': notes,
        'videoUrl': videoUrl,
        'targetMuscle': targetMuscle,
      };
}

