import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../../domain/entities/user.dart';

/// Service for Plan Builder business logic
/// Separates data operations from UI concerns
class PlanBuilderService {
  final RemoteDataSource _remoteDataSource;

  PlanBuilderService(this._remoteDataSource);

  /// Validate plan data before saving
  Map<String, String?> validatePlanData({
    required String name,
    required String? description,
    required String? difficulty,
    required List<Map<String, dynamic>> workoutDays,
    String? trainerId,
    double? weeklyCost,
  }) {
    final errors = <String, String?>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Plan name is required';
    }

    if (difficulty == null || difficulty.isEmpty) {
      errors['difficulty'] = 'Difficulty level is required';
    }

    if (workoutDays.isEmpty) {
      errors['workoutDays'] = 'At least one workout day is required';
    }

    // Validate each workout day
    for (var i = 0; i < workoutDays.length; i++) {
      final day = workoutDays[i];
      final dayName = day['name'] as String?;
      final isRestDay = day['isRestDay'] as bool? ?? false;
      final exercises = day['exercises'] as List? ?? [];

      if (dayName == null || dayName.trim().isEmpty) {
        errors['workoutDay_$i'] = 'Day ${i + 1} name is required';
      }

      if (!isRestDay && exercises.isEmpty) {
        errors['workoutDay_${i}_exercises'] = 'Day ${i + 1} needs exercises or mark as rest day';
      }

      // Validate exercises
      for (var j = 0; j < exercises.length; j++) {
        final exercise = exercises[j] as Map<String, dynamic>;
        final exerciseName = exercise['name'] as String?;
        final sets = exercise['sets'];
        final reps = exercise['reps'];

        if (exerciseName == null || exerciseName.trim().isEmpty) {
          errors['exercise_${i}_$j'] = 'Exercise ${j + 1} name is required';
        }

        if (sets == null || sets <= 0) {
          errors['exercise_${i}_${j}_sets'] = 'Sets must be greater than 0';
        }

        if (reps == null) {
          errors['exercise_${i}_${j}_reps'] = 'Reps is required';
        }
      }
    }

    return errors;
  }

  /// Build plan data payload for API
  Map<String, dynamic> buildPlanPayload({
    required String name,
    required String? description,
    required String difficulty,
    required List<Map<String, dynamic>> workoutDays,
    required bool isTemplate,
    String? trainerId,
    double? weeklyCost,
  }) {
    final planData = <String, dynamic>{
      'name': name.trim(),
      'description': description?.trim() ?? '',
      'difficulty': difficulty,
      'workouts': workoutDays,
      'isTemplate': isTemplate,
    };

    if (trainerId != null && trainerId.isNotEmpty) {
      planData['trainerId'] = trainerId;
    }

    if (weeklyCost != null && weeklyCost > 0) {
      planData['weeklyCost'] = weeklyCost;
    }

    return planData;
  }

  /// Create a new plan
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData) async {
    try {
      debugPrint('[PlanBuilderService] Creating plan: ${planData['name']}');
      final result = await _remoteDataSource.createPlan(planData);
      debugPrint('[PlanBuilderService] ✓ Plan created: ${result['_id']}');
      return result;
    } catch (e) {
      debugPrint('[PlanBuilderService] ✗ Failed to create plan: $e');
      rethrow;
    }
  }

  /// Update existing plan
  Future<Map<String, dynamic>> updatePlan(
    String planId,
    Map<String, dynamic> planData,
  ) async {
    try {
      debugPrint('[PlanBuilderService] Updating plan: $planId');
      final result = await _remoteDataSource.updatePlan(planId, planData);
      debugPrint('[PlanBuilderService] ✓ Plan updated: $planId');
      return result;
    } catch (e) {
      debugPrint('[PlanBuilderService] ✗ Failed to update plan: $e');
      rethrow;
    }
  }

  /// Check if plan can be edited directly (not assigned to clients)
  bool canEditPlanDirectly(Map<String, dynamic>? plan) {
    if (plan == null) return true; // New plan

    final isTemplate = plan['isTemplate'] as bool? ?? false;
    final assignedClients = plan['assignedClientIds'] as List? ?? [];

    // Can edit if it's a template OR has no assigned clients
    return isTemplate || assignedClients.isEmpty;
  }

  /// Get assigned clients count
  int getAssignedClientsCount(Map<String, dynamic>? plan) {
    if (plan == null) return 0;
    final assignedClients = plan['assignedClientIds'] as List? ?? [];
    return assignedClients.length;
  }

  /// Extract trainer ID from plan data
  String? extractTrainerId(Map<String, dynamic>? plan, List<User> trainers) {
    if (plan == null) return null;

    final trainerIdValue = plan['trainerId'];
    if (trainerIdValue == null) return null;

    String? extractedId;

    if (trainerIdValue is Map) {
      // Try userId first (matches User.id), then _id (trainer profile ID)
      extractedId = trainerIdValue['userId']?.toString() ?? 
                    trainerIdValue['_id']?.toString();
    } else {
      extractedId = trainerIdValue.toString();
    }

    if (extractedId == null) return null;

    // Verify trainer exists in list
    final trainerExists = trainers.any((t) => t.id == extractedId);
    if (!trainerExists) {
      debugPrint('[PlanBuilderService] WARNING: Trainer ID $extractedId not found in trainers list');
      return null;
    }

    return extractedId;
  }

  /// Parse workout days from plan
  List<Map<String, dynamic>> parseWorkoutDays(Map<String, dynamic>? plan) {
    if (plan == null) return [];

    final workouts = plan['workouts'] as List? ?? [];
    return workouts.map((w) => w as Map<String, dynamic>).toList();
  }

  /// Generate a unique name for duplicated plan
  String generateDuplicatePlanName(String originalName) {
    // Remove existing suffixes
    final cleanName = originalName
        .replaceAll(RegExp(r'\s*\(Copy\)\s*$'), '')
        .replaceAll(RegExp(r'\s*\(New\)\s*$'), '')
        .trim();

    return '$cleanName (Copy)';
  }
}

