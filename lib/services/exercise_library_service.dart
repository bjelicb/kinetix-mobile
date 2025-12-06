import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import '../domain/entities/exercise.dart';
import 'package:uuid/uuid.dart';

class ExerciseLibraryService {
  static ExerciseLibraryService? _instance;
  static ExerciseLibraryService get instance {
    _instance ??= ExerciseLibraryService._();
    return _instance!;
  }

  ExerciseLibraryService._();

  List<Exercise>? _cachedExercises;
  bool _isLoading = false;

  Future<List<Exercise>> loadExercises() async {
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }

    if (_isLoading) {
      // Wait for ongoing load
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedExercises ?? [];
    }

    _isLoading = true;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/exercises.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> exercisesJson = jsonData['exercises'] as List<dynamic>;

      _cachedExercises = exercisesJson.map((json) {
        return Exercise(
          id: json['id'] as String? ?? const Uuid().v4(),
          name: json['name'] as String,
          targetMuscle: json['targetMuscle'] as String,
          sets: [],
          category: json['category'] as String?,
          equipment: json['equipment'] != null
              ? List<String>.from(json['equipment'] as List)
              : null,
          instructions: json['instructions'] as String?,
        );
      }).toList();

      return _cachedExercises!;
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      return [];
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Exercise>> getAllExercises() async {
    return await loadExercises();
  }

  Future<List<Exercise>> getExercisesByCategory(String category) async {
    final exercises = await loadExercises();
    return exercises.where((e) => e.category == category).toList();
  }

  Future<List<Exercise>> getExercisesByEquipment(List<String> equipment) async {
    final exercises = await loadExercises();
    return exercises.where((e) {
      if (e.equipment == null) return false;
      return equipment.any((eq) => e.equipment!.contains(eq));
    }).toList();
  }

  Future<List<Exercise>> searchExercises(String query) async {
    if (query.isEmpty) {
      return await getAllExercises();
    }

    final exercises = await loadExercises();
    final lowerQuery = query.toLowerCase();

    return exercises.where((exercise) {
      final nameMatch = exercise.name.toLowerCase().contains(lowerQuery);
      final muscleMatch = exercise.targetMuscle.toLowerCase().contains(lowerQuery);
      final categoryMatch = exercise.category?.toLowerCase().contains(lowerQuery) ?? false;
      final equipmentMatch = exercise.equipment?.any(
        (eq) => eq.toLowerCase().contains(lowerQuery),
      ) ?? false;

      return nameMatch || muscleMatch || categoryMatch || equipmentMatch;
    }).toList();
  }

  Future<List<String>> getAllCategories() async {
    final exercises = await loadExercises();
    final categories = exercises
        .where((e) => e.category != null)
        .map((e) => e.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  Future<List<String>> getAllEquipment() async {
    final exercises = await loadExercises();
    final equipment = <String>{};
    for (final exercise in exercises) {
      if (exercise.equipment != null) {
        equipment.addAll(exercise.equipment!);
      }
    }
    final equipmentList = equipment.toList();
    equipmentList.sort();
    return equipmentList;
  }

  void clearCache() {
    _cachedExercises = null;
  }
}

