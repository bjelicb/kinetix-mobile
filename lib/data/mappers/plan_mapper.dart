import '../../domain/entities/plan.dart';
import '../models/plan_collection.dart' if (dart.library.html) '../models/plan_collection_stub.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class PlanMapper {
  /// Convert DTO from backend to domain entity
  static Plan toEntity(Map<String, dynamic> dto) {
    debugPrint('[PlanMapper] toEntity() START');
    debugPrint('[PlanMapper] → DTO keys: ${dto.keys.toList()}');
    
    // Extract trainerId from either ObjectId or populated object
    String trainerId;
    final trainerIdField = dto['trainerId'];
    if (trainerIdField is String) {
      trainerId = trainerIdField;
      debugPrint('[PlanMapper] → trainerId (String): $trainerId');
    } else if (trainerIdField is Map) {
      trainerId = trainerIdField['_id']?.toString() ?? '';
      debugPrint('[PlanMapper] → trainerId (Map): $trainerId');
    } else {
      trainerId = trainerIdField.toString();
      debugPrint('[PlanMapper] → trainerId (Other): $trainerId');
    }
    
    // Backend sends 'workouts' but we use 'workoutDays'
    final workoutsField = dto['workouts'] as List<dynamic>? ?? [];
    debugPrint('[PlanMapper] → Workouts field type: ${dto['workouts'].runtimeType}');
    debugPrint('[PlanMapper] → Workouts field raw: ${dto['workouts']}');
    debugPrint('[PlanMapper] → Workouts field length: ${workoutsField.length}');
    if (workoutsField.isNotEmpty) {
      debugPrint('[PlanMapper] → First workout day: ${workoutsField.first}');
    }
    
    final planId = dto['_id']?.toString() ?? '';
    final planName = dto['name'] as String? ?? '';
    debugPrint('[PlanMapper] → Plan ID: $planId');
    debugPrint('[PlanMapper] → Plan name: $planName');
    
    final plan = Plan(
      id: planId,
      name: planName,
      difficulty: dto['difficulty'] as String? ?? 'INTERMEDIATE',
      description: dto['description'] as String?,
      trainerId: trainerId,
      workoutDays: workoutsField
          .map((w) => _workoutDayFromDto(w as Map<String, dynamic>))
          .toList(),
    );
    
    debugPrint('[PlanMapper] ✓ Entity created: ${plan.name} with ${plan.workoutDays.length} workout days');
    return plan;
  }
  
  /// Convert domain entity to Isar collection
  static PlanCollection toCollection(Plan entity) {
    return PlanCollection()
      ..planId = entity.id
      ..name = entity.name
      ..difficulty = entity.difficulty
      ..description = entity.description
      ..trainerId = entity.trainerId
      ..workoutDays = entity.workoutDays
          .map((day) => _workoutDayToEmbedded(day))
          .toList()
      ..isDirty = false
      ..updatedAt = DateTime.now()
      ..lastSync = DateTime.now();
  }
  
  /// Convert Isar collection to domain entity
  static Plan fromCollection(PlanCollection collection) {
    return Plan(
      id: collection.planId,
      name: collection.name,
      difficulty: collection.difficulty,
      description: collection.description,
      trainerId: collection.trainerId,
      workoutDays: collection.workoutDays
          .map((day) => _workoutDayFromEmbedded(day))
          .toList(),
    );
  }
  
  /// Convert domain entity to DTO for API push
  static Map<String, dynamic> toDto(Plan entity) {
    return {
      '_id': entity.id,
      'name': entity.name,
      'difficulty': entity.difficulty,
      'description': entity.description,
      'trainerId': entity.trainerId,
      'workouts': entity.workoutDays
          .map((day) => _workoutDayToDto(day))
          .toList(),
    };
  }
  
  // Helper methods for WorkoutDay conversion
  
  static WorkoutDay _workoutDayFromDto(Map<String, dynamic> dto) {
    final exercisesField = dto['exercises'] as List<dynamic>? ?? [];
    
    return WorkoutDay(
      dayOfWeek: dto['dayOfWeek'] as int? ?? 1,
      isRestDay: dto['isRestDay'] as bool? ?? false,
      name: dto['name'] as String? ?? '',
      exercises: exercisesField
          .map((e) => _exerciseFromDto(e as Map<String, dynamic>))
          .toList(),
      estimatedDuration: dto['estimatedDuration'] as int? ?? 60,
      notes: dto['notes'] as String?,
    );
  }
  
  static WorkoutDayEmbedded _workoutDayToEmbedded(WorkoutDay entity) {
    return WorkoutDayEmbedded()
      ..dayOfWeek = entity.dayOfWeek
      ..isRestDay = entity.isRestDay
      ..name = entity.name
      ..exercises = entity.exercises
          .map((ex) => _exerciseToEmbedded(ex))
          .toList()
      ..estimatedDuration = entity.estimatedDuration
      ..notes = entity.notes;
  }
  
  static WorkoutDay _workoutDayFromEmbedded(WorkoutDayEmbedded embedded) {
    return WorkoutDay(
      dayOfWeek: embedded.dayOfWeek,
      isRestDay: embedded.isRestDay,
      name: embedded.name,
      exercises: embedded.exercises
          .map((ex) => _exerciseFromEmbedded(ex))
          .toList(),
      estimatedDuration: embedded.estimatedDuration,
      notes: embedded.notes,
    );
  }
  
  static Map<String, dynamic> _workoutDayToDto(WorkoutDay entity) {
    return {
      'dayOfWeek': entity.dayOfWeek,
      'isRestDay': entity.isRestDay,
      'name': entity.name,
      'exercises': entity.exercises
          .map((ex) => _exerciseToDto(ex))
          .toList(),
      'estimatedDuration': entity.estimatedDuration,
      'notes': entity.notes,
    };
  }
  
  // Helper methods for Exercise conversion
  
  static PlanExercise _exerciseFromDto(Map<String, dynamic> dto) {
    return PlanExercise(
      name: dto['name'] as String? ?? '',
      sets: dto['sets'] as int? ?? 0,
      reps: dto['reps']?.toString() ?? '0',
      restSeconds: dto['restSeconds'] as int? ?? 60,
      notes: dto['notes'] as String?,
      videoUrl: dto['videoUrl'] as String?,
      targetMuscle: dto['targetMuscle'] as String?,
    );
  }
  
  static ExerciseEmbedded _exerciseToEmbedded(PlanExercise entity) {
    return ExerciseEmbedded()
      ..name = entity.name
      ..sets = entity.sets
      ..reps = entity.reps
      ..restSeconds = entity.restSeconds
      ..notes = entity.notes
      ..videoUrl = entity.videoUrl
      ..targetMuscle = entity.targetMuscle;
  }
  
  static PlanExercise _exerciseFromEmbedded(ExerciseEmbedded embedded) {
    return PlanExercise(
      name: embedded.name,
      sets: embedded.sets,
      reps: embedded.reps,
      restSeconds: embedded.restSeconds,
      notes: embedded.notes,
      videoUrl: embedded.videoUrl,
      targetMuscle: embedded.targetMuscle,
    );
  }
  
  static Map<String, dynamic> _exerciseToDto(PlanExercise entity) {
    return {
      'name': entity.name,
      'sets': entity.sets,
      'reps': entity.reps,
      'restSeconds': entity.restSeconds,
      'notes': entity.notes,
      'videoUrl': entity.videoUrl,
      'targetMuscle': entity.targetMuscle,
    };
  }
}

