import '../../../../domain/entities/exercise.dart';
import '../../../../services/exercise_library_service.dart';

/// Service for exercise search and filtering logic
class ExerciseSearchService {
  /// Loads all exercises and available equipment from the exercise library
  static Future<ExerciseSearchLoadResult> loadExercises() async {
    try {
      final exerciseService = ExerciseLibraryService.instance;
      final allExercises = await exerciseService.getAllExercises();
      final availableEquipment = await exerciseService.getAllEquipment();
      
      return ExerciseSearchLoadResult(
        exercises: allExercises,
        availableEquipment: availableEquipment,
      );
    } catch (e) {
      return ExerciseSearchLoadResult(
        exercises: [],
        availableEquipment: [],
      );
    }
  }

  /// Filters exercises based on search query, muscle groups, and equipment
  /// Handles search caching to improve performance
  static Future<List<Exercise>> filterExercises({
    required List<Exercise> allExercises,
    required String searchQuery,
    required List<String> selectedMuscleGroups,
    required List<String> selectedEquipment,
    required Map<String, List<Exercise>> searchCache,
  }) async {
    List<Exercise> filtered = allExercises;

    // Search filter with cache
    final query = searchQuery.toLowerCase().trim();
    if (query.isNotEmpty) {
      if (searchCache.containsKey(query)) {
        filtered = searchCache[query]!;
      } else {
        final exerciseService = ExerciseLibraryService.instance;
        filtered = await exerciseService.searchExercises(query);
        searchCache[query] = filtered;
        // Limit cache size to prevent memory issues
        if (searchCache.length > 50) {
          final firstKey = searchCache.keys.first;
          searchCache.remove(firstKey);
        }
      }
    }

    // Muscle group filter
    if (selectedMuscleGroups.isNotEmpty) {
      filtered = filtered.where((exercise) {
        return selectedMuscleGroups.contains(exercise.targetMuscle);
      }).toList();
    }

    // Equipment filter
    if (selectedEquipment.isNotEmpty) {
      filtered = filtered.where((exercise) {
        if (exercise.equipment == null) return false;
        return selectedEquipment.any((eq) => exercise.equipment!.contains(eq));
      }).toList();
    }

    return filtered;
  }

  /// Gets available muscle groups from exercises list
  static List<String> getAvailableMuscleGroups(List<Exercise> exercises) {
    return exercises
        .map((e) => e.targetMuscle)
        .toSet()
        .toList()
      ..sort();
  }
}

/// Result of loading exercises
class ExerciseSearchLoadResult {
  final List<Exercise> exercises;
  final List<String> availableEquipment;

  ExerciseSearchLoadResult({
    required this.exercises,
    required this.availableEquipment,
  });
}

