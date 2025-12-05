import '../../domain/entities/exercise.dart' as domain;
import '../models/exercise_collection.dart' if (dart.library.html) '../models/exercise_collection_stub.dart' as isar_models;

class ExerciseMapper {
  static domain.Exercise toEntity(isar_models.ExerciseCollection collection) {
    return domain.Exercise(
      id: collection.id.toString(),
      name: collection.name,
      targetMuscle: collection.targetMuscle,
      sets: collection.sets.map((set) => domain.WorkoutSet(
        id: set.id,
        weight: set.weight,
        reps: set.reps,
        rpe: set.rpe,
        isCompleted: set.isCompleted,
      )).toList(),
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
      }).toList();
    
    if (isarId != null) {
      collection.id = isarId;
    }
    
    return collection;
  }
}

