import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart' as domain;
import '../models/workout_collection.dart' if (dart.library.html) '../models/workout_collection_stub.dart';

class WorkoutMapper {
  static Workout toEntity(WorkoutCollection collection, List<domain.Exercise> exercises) {
    return Workout(
      id: collection.id.toString(),
      serverId: collection.serverId.isEmpty ? null : collection.serverId,
      name: collection.name,
      planId: collection.planId,
      scheduledDate: collection.scheduledDate,
      dayOfWeek: collection.dayOfWeek,
      isCompleted: collection.isCompleted,
      isMissed: collection.isMissed,
      isRestDay: collection.isRestDay,
      exercises: exercises,
      isDirty: collection.isDirty,
      isSyncing: collection.isSyncing,
      updatedAt: collection.updatedAt,
    );
  }

  static WorkoutCollection toCollection(Workout entity, {int? isarId}) {
    final collection = WorkoutCollection()
      ..serverId = entity.serverId ?? ''
      ..name = entity.name
      ..planId = entity.planId
      ..scheduledDate = entity.scheduledDate
      ..dayOfWeek = entity.dayOfWeek
      ..isCompleted = entity.isCompleted
      ..isMissed = entity.isMissed
      ..isRestDay = entity.isRestDay
      ..isDirty = entity.isDirty
      ..isSyncing = entity.isSyncing
      ..updatedAt = entity.updatedAt;

    if (isarId != null) {
      collection.id = isarId;
    }

    return collection;
  }
}
