import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../../domain/entities/user.dart';
import 'models/plan_builder_models.dart';
import 'models/loaded_plan_data.dart';

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

  /// Load existing plan data for initialization
  LoadedPlanData loadExistingPlan({
    required Map<String, dynamic> plan,
    required String? widgetTrainerId,
    required double? initialWeeklyCost,
    required List<User> trainers,
  }) {
    final name = plan['name'] ?? '';
    final description = plan['description'] ?? '';
    final difficulty = plan['difficulty'] ?? 'BEGINNER';
    
    // Load weekly cost - prioritize from widget if provided, otherwise from plan
    String? weeklyCost;
    if (initialWeeklyCost != null && initialWeeklyCost > 0) {
      weeklyCost = initialWeeklyCost.toStringAsFixed(2);
    } else {
      final planWeeklyCost = plan['weeklyCost'];
      if (planWeeklyCost != null) {
        if (planWeeklyCost is num) {
          weeklyCost = planWeeklyCost.toDouble().toStringAsFixed(2);
        } else if (planWeeklyCost is String) {
          final costValue = double.tryParse(planWeeklyCost);
          if (costValue != null) {
            weeklyCost = costValue.toStringAsFixed(2);
          }
        }
      }
    }
    
    // Extract trainer ID - simplified logic
    String? extractedTrainerId;
    
    // Try widget.trainerId first (from modal)
    if (widgetTrainerId != null && widgetTrainerId.toString().trim().isNotEmpty) {
      if (widgetTrainerId is Map) {
        final trainerMap = widgetTrainerId as Map;
        extractedTrainerId = (trainerMap['userId'] ?? trainerMap['_id'] ?? trainerMap['id'])?.toString();
      } else {
        extractedTrainerId = widgetTrainerId.toString().trim();
      }
    }
    
    // Fallback to plan's trainerId
    if ((extractedTrainerId == null || extractedTrainerId.isEmpty) && plan['trainerId'] != null) {
      extractedTrainerId = extractTrainerId(plan, trainers);
    }
    
    // Verify trainer exists in trainers list
    if (extractedTrainerId != null && trainers.isNotEmpty) {
      final trainerExists = trainers.any((t) => t.id == extractedTrainerId);
      if (!trainerExists) {
        debugPrint('[PlanBuilderService] WARNING: Trainer ID $extractedTrainerId not found in trainers list');
        extractedTrainerId = null;
      }
    }
    
    // Check if plan can be edited
    final isTemplate = plan['isTemplate'] == true;
    final assignedClientIds = plan['assignedClientIds'] as List<dynamic>? ?? [];
    final isPlanEditable = isTemplate || assignedClientIds.isEmpty;
    
    if (!isPlanEditable) {
      debugPrint('[PlanBuilderService] WARNING: Plan is assigned to ${assignedClientIds.length} clients - editing may fail');
    }
    
    // Load workout days
    final workouts = plan['workouts'] as List<dynamic>? ?? [];
    final workoutDays = workouts.map((w) {
      final exercises = (w['exercises'] as List<dynamic>? ?? []).map((e) {
        return ExerciseData(
          name: e['name'] ?? '',
          sets: e['sets'] ?? 3,
          reps: e['reps']?.toString() ?? '10',
          restSeconds: e['restSeconds'] ?? 60,
          notes: e['notes'],
          videoUrl: e['videoUrl'],
        );
      }).toList();
      
      return WorkoutDayData(
        dayOfWeek: w['dayOfWeek'] ?? 1,
        name: w['name'] ?? '',
        isRestDay: w['isRestDay'] ?? false,
        exercises: exercises,
        notes: w['notes'],
      );
    }).toList();
    
    return LoadedPlanData(
      name: name,
      description: description,
      difficulty: difficulty,
      weeklyCost: weeklyCost,
      selectedTrainerId: extractedTrainerId,
      workoutDays: workoutDays,
      isPlanEditable: isPlanEditable,
    );
  }

  /// Convert WorkoutDayData list to Map format for validation/payload
  List<Map<String, dynamic>> workoutDaysToMap(List<WorkoutDayData> workoutDays) {
    return workoutDays.map((day) {
      return {
        'dayOfWeek': day.dayOfWeek,
        'isRestDay': day.isRestDay,
        'name': day.name,
        'exercises': day.exercises.map((ex) {
          return {
            'name': ex.name,
            'sets': ex.sets,
            'reps': ex.reps,
            'restSeconds': ex.restSeconds,
            'notes': ex.notes,
          };
        }).toList(),
        'notes': day.notes,
      };
    }).toList();
  }

  /// Validate plan using WorkoutDayData
  List<String> validatePlan({
    required String name,
    required String? trainerId,
    required List<WorkoutDayData> workoutDays,
  }) {
    final errors = <String>[];
    
    if (name.trim().isEmpty) {
      errors.add('Plan name is required');
    }
    
    if (trainerId == null) {
      errors.add('Trainer is required');
    }
    
    if (workoutDays.isEmpty) {
      errors.add('At least one workout day is required');
    }
    
    for (int i = 0; i < workoutDays.length; i++) {
      final day = workoutDays[i];
      if (!day.isRestDay) {
        if (day.name.trim().isEmpty) {
          errors.add('Day ${i + 1}: Workout name is required');
        }
        
        if (day.exercises.isEmpty) {
          errors.add('Day ${i + 1}: At least one exercise is required');
        }
        
        for (int j = 0; j < day.exercises.length; j++) {
          final exercise = day.exercises[j];
          if (exercise.name.trim().isEmpty) {
            errors.add('Day ${i + 1}, Exercise ${j + 1}: Exercise name is required');
          }
        }
      }
    }
    
    return errors;
  }

  /// Prepare plan data for saving, handling trainer ID extraction
  Map<String, dynamic> preparePlanDataForSave({
    required String name,
    required String description,
    required String difficulty,
    required List<WorkoutDayData> workoutDays,
    required String? selectedTrainerId,
    required String? widgetTrainerId,
    required String? weeklyCostText,
    required Map<String, dynamic>? existingPlan,
  }) {
    final workouts = workoutDaysToMap(workoutDays);
    
    final planData = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'difficulty': difficulty,
      'workouts': workouts,
      'isTemplate': false,
    };
    
    // Add trainer ID - prioritize selected trainer, fallback to widget trainerId
    if (selectedTrainerId != null) {
      planData['trainerId'] = selectedTrainerId;
    } else if (widgetTrainerId != null) {
      if (widgetTrainerId is Map) {
        final trainerMap = widgetTrainerId as Map;
        planData['trainerId'] = trainerMap['userId']?.toString() ?? trainerMap['_id']?.toString();
      } else {
        planData['trainerId'] = widgetTrainerId.toString();
      }
    }
    
    // Add weekly cost if provided
    if (weeklyCostText != null && weeklyCostText.trim().isNotEmpty) {
      final costValue = double.tryParse(weeklyCostText.trim());
      if (costValue != null && costValue > 0) {
        planData['weeklyCost'] = costValue;
      }
    } else if (existingPlan != null) {
      // Copy from existing plan if not set in form
      final existingCost = existingPlan['weeklyCost'];
      if (existingCost != null) {
        if (existingCost is num) {
          planData['weeklyCost'] = existingCost.toDouble();
        }
      }
    }
    
    return planData;
  }

  /// Create duplicate plan data with modified name
  Map<String, dynamic> createDuplicatePlanData({
    required Map<String, dynamic> originalPlanData,
    required String originalName,
    required String? selectedTrainerId,
    required String? widgetTrainerId,
    required String? weeklyCostText,
    required Map<String, dynamic>? existingPlan,
  }) {
    final newPlanData = Map<String, dynamic>.from(originalPlanData);
    
    // Generate duplicate name
    String newName = originalName;
    if (!originalName.toLowerCase().contains('(copy)') && 
        !originalName.toLowerCase().contains('(new)') &&
        !originalName.toLowerCase().contains('[copy]')) {
      newName = generateDuplicatePlanName(originalName);
    } else {
      // If it already has a suffix, add timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(10);
      newName = '$originalName $timestamp';
    }
    
    newPlanData['name'] = newName;
    
    // Ensure trainer and cost are copied
    if (selectedTrainerId != null) {
      newPlanData['trainerId'] = selectedTrainerId;
    } else if (widgetTrainerId != null) {
      newPlanData['trainerId'] = widgetTrainerId;
    }
    
    // Ensure weekly cost is copied
    if (weeklyCostText != null && weeklyCostText.trim().isNotEmpty) {
      final costValue = double.tryParse(weeklyCostText.trim());
      if (costValue != null && costValue > 0) {
        newPlanData['weeklyCost'] = costValue;
      }
    } else if (existingPlan != null) {
      final existingCost = existingPlan['weeklyCost'];
      if (existingCost != null && existingCost is num) {
        newPlanData['weeklyCost'] = existingCost.toDouble();
      }
    }
    
    return newPlanData;
  }

  /// Check if error is an authentication error
  bool isAuthenticationError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') || errorStr.contains('unauthorized');
  }

  /// Check if error is an assignment/template error
  bool isAssignmentError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return (errorStr.contains('400') && !errorStr.contains('401')) ||
           errorStr.contains('assigned') ||
           errorStr.contains('template') ||
           errorStr.contains('cannot update') ||
           errorStr.contains('not a template');
  }

  /// Extract error message from exception
  String extractErrorMessage(dynamic error) {
    return error.toString().replaceAll('Exception: ', '').split('\n').first;
  }
}

