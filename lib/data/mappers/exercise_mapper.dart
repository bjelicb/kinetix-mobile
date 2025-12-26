import '../../domain/entities/exercise.dart' as domain;
import '../models/exercise_collection.dart' if (dart.library.html) '../models/exercise_collection_stub.dart' as isar_models;
import 'package:uuid/uuid.dart';

class ExerciseMapper {
  static domain.Exercise toEntity(isar_models.ExerciseCollection collection) {
    // Get existing sets or initialize empty sets based on planSets
    List<domain.WorkoutSet> sets;
    if (collection.sets.isNotEmpty) {
      // Use existing completed sets
      sets = collection.sets.map((set) {
        return domain.WorkoutSet(
          id: set.id,
          weight: set.weight,
          reps: set.reps,
          rpe: set.rpe,
          isCompleted: set.isCompleted,
        );
      }).toList();
    } else if (collection.planSets != null && collection.planSets! > 0) {
      // Initialize empty sets based on planSets
      // Parse planReps to get default reps value
      int defaultReps = 0;
      if (collection.planReps != null) {
        if (collection.planReps is int) {
          defaultReps = collection.planReps as int;
        } else if (collection.planReps is String) {
          // Parse string like "10" or "10-12" - take first number
          final repsStr = collection.planReps as String;
          final match = RegExp(r'(\d+)').firstMatch(repsStr);
          if (match != null) {
            defaultReps = int.tryParse(match.group(1) ?? '0') ?? 0;
          }
        }
      }
      
      sets = List.generate(collection.planSets!, (index) {
        return domain.WorkoutSet(
          id: const Uuid().v4(), // Generate UUID for new set
          weight: 0.0,
          reps: defaultReps,
          rpe: null,
          isCompleted: false,
        );
      });
    } else {
      sets = [];
    }
    
    return domain.Exercise(
      id: collection.id.toString(),
      name: collection.name,
      targetMuscle: collection.targetMuscle,
      sets: sets,
      // Map plan metadata from Isar collection
      planSets: collection.planSets,
      planReps: collection.planReps,
      restSeconds: collection.restSeconds,
      notes: collection.notes,
    );
  }
  
  static isar_models.ExerciseCollection toCollection(domain.Exercise entity, {int? isarId}) {
    final collection = isar_models.ExerciseCollection()
      ..name = entity.name
      ..targetMuscle = entity.targetMuscle
      ..sets = entity.sets.map((set) {
        final workoutSet = isar_models.WorkoutSet()
          ..id = set.id
          ..weight = set.weight
          ..reps = set.reps
          ..rpe = set.rpe
          ..isCompleted = set.isCompleted;
        return workoutSet;
      }).toList()
      ..planSets = entity.planSets
      ..planReps = entity.planReps?.toString()
      ..restSeconds = entity.restSeconds
      ..notes = entity.notes;
    
    if (isarId != null) {
      collection.id = isarId;
    }
    
    return collection;
  }
}

