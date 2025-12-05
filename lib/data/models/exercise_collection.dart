import 'package:isar/isar.dart';

part 'exercise_collection.g.dart';

@embedded
class WorkoutSet {
  late String id; // UUID
  late double weight;
  late int reps;
  double? rpe;
  late bool isCompleted;
  
  WorkoutSet();
  
  WorkoutSet.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        weight = (json['weight'] as num).toDouble(),
        reps = json['reps'] as int,
        rpe = json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
        isCompleted = json['isCompleted'] as bool? ?? false;
  
  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
        'isCompleted': isCompleted,
      };
}

@collection
class ExerciseCollection {
  Id id = Isar.autoIncrement;
  
  late String name;
  late String targetMuscle;
  
  // Embedded Sets for performance
  List<WorkoutSet> sets = [];
  
  ExerciseCollection();
  
  ExerciseCollection.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        targetMuscle = json['targetMuscle'] as String,
        sets = (json['sets'] as List<dynamic>?)
                ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
  
  Map<String, dynamic> toJson() => {
        'name': name,
        'targetMuscle': targetMuscle,
        'sets': sets.map((e) => e.toJson()).toList(),
      };
}

