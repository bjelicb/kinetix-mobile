import 'package:uuid/uuid.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../data/models/workout_template.dart';
import '../../../../services/exercise_library_service.dart';

/// Service for workout template business logic
class WorkoutTemplateEditService {
  /// Load exercise library for template conversion
  static Future<List<Exercise>> loadExerciseLibrary() async {
    return await ExerciseLibraryService.instance.loadExercises();
  }

  /// Convert template exercises to Exercise entities
  static List<Exercise> convertTemplateToExercises(
    WorkoutTemplate template,
    List<Exercise> exerciseLibrary,
  ) {
    final exercises = <Exercise>[];

    for (final templateExercise in template.exercises) {
      final libraryExercise = exerciseLibrary.firstWhere(
        (e) => e.id == templateExercise.exerciseId,
        orElse: () => Exercise(
          id: templateExercise.exerciseId,
          name: templateExercise.name,
          targetMuscle: '',
          sets: List.generate(
            templateExercise.defaultSets,
            (index) => WorkoutSet(
              id: const Uuid().v4(),
              weight: templateExercise.defaultWeight ?? 0.0,
              reps: templateExercise.defaultReps ?? 10,
              rpe: null,
              isCompleted: false,
            ),
          ),
        ),
      );

      // If exercise found in library, use library data with template sets
      if (exerciseLibrary.any((e) => e.id == templateExercise.exerciseId)) {
        exercises.add(Exercise(
          id: libraryExercise.id,
          name: libraryExercise.name,
          targetMuscle: libraryExercise.targetMuscle,
          sets: List.generate(
            templateExercise.defaultSets,
            (index) => WorkoutSet(
              id: const Uuid().v4(),
              weight: templateExercise.defaultWeight ?? 0.0,
              reps: templateExercise.defaultReps ?? 10,
              rpe: null,
              isCompleted: false,
            ),
          ),
          category: libraryExercise.category,
          equipment: libraryExercise.equipment,
          instructions: libraryExercise.instructions,
        ));
      } else {
        // Exercise not in library, use template data
        exercises.add(libraryExercise);
      }
    }

    return exercises;
  }

  /// Apply template to workout exercises
  static Future<List<Exercise>> applyTemplate(WorkoutTemplate template) async {
    final exerciseLibrary = await loadExerciseLibrary();
    return convertTemplateToExercises(template, exerciseLibrary);
  }
}

