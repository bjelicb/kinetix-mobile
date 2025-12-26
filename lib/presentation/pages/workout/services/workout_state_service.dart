import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../domain/entities/workout.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/exercise.dart' as domain;
import '../../../../presentation/controllers/workout_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../../data/datasources/remote_data_source.dart' show remoteDataSourceProvider;

/// Service for managing workout state mutations
class WorkoutStateService {
  /// Retry local workout update with exponential backoff
  /// Returns true if update succeeded, false otherwise
  static Future<bool> _retryLocalUpdate({
    required Workout updatedWorkout,
    required WidgetRef ref,
    int maxRetries = 2,
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        await ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
        debugPrint(
          '[WorkoutStateService:Retry] Local workout update succeeded (attempt ${retryCount + 1}/${maxRetries + 1})',
        );
        return true;
      } catch (e) {
        retryCount++;
        if (retryCount <= maxRetries) {
          debugPrint(
            '[WorkoutStateService:Retry] Local update failed (attempt $retryCount/${maxRetries + 1}), retrying: $e',
          );
          await Future.delayed(Duration(seconds: retryCount)); // Exponential backoff
        } else {
          debugPrint(
            '[WorkoutStateService:Retry] ⚠️ WARNING: Local update failed after ${maxRetries + 1} attempts: $e',
          );
          return false;
        }
      }
    }

    return false;
  }

  /// Create updated Workout entity with optional field overrides
  /// Uses original values if optional parameters are not provided
  static Workout _createUpdatedWorkout({
    required Workout originalWorkout,
    String? serverId,
    String? planId,
    int? dayOfWeek,
    bool? isCompleted,
    bool? isMissed,
    bool? isDirty,
    bool? isSyncing,
    List<Exercise>? exercises,
  }) {
    return Workout(
      id: originalWorkout.id,
      serverId: serverId ?? originalWorkout.serverId,
      name: originalWorkout.name,
      planId: planId ?? originalWorkout.planId,
      scheduledDate: originalWorkout.scheduledDate,
      dayOfWeek: dayOfWeek ?? originalWorkout.dayOfWeek,
      isCompleted: isCompleted ?? originalWorkout.isCompleted,
      isMissed: isMissed ?? originalWorkout.isMissed,
      isRestDay: originalWorkout.isRestDay,
      exercises: exercises ?? originalWorkout.exercises,
      isDirty: isDirty ?? originalWorkout.isDirty,
      isSyncing: isSyncing ?? originalWorkout.isSyncing,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert backend WorkoutLog to Workout entity
  /// Uses same logic as _workoutLogFromServerData() in workout_repository_impl.dart
  /// This ensures consistent mapping between API response and Workout entity
  static Workout _convertWorkoutLogToWorkout(dynamic logData) {
    final serverId = logData['_id']?.toString() ?? logData['id']?.toString() ?? '';
    final workoutDate = DateTime.parse(logData['workoutDate'] as String);
    final isCompleted = logData['isCompleted'] as bool? ?? false;
    final isMissed = logData['isMissed'] as bool? ?? false;

    // Extract planId from weeklyPlanId
    String? planId;
    if (logData['weeklyPlanId'] != null) {
      if (logData['weeklyPlanId'] is String) {
        planId = logData['weeklyPlanId'] as String;
      } else if (logData['weeklyPlanId'] is Map) {
        final weeklyPlanIdMap = logData['weeklyPlanId'] as Map<String, dynamic>;
        planId = weeklyPlanIdMap['_id']?.toString();
      }
    }

    // Extract dayOfWeek from logData (Plan day index 1-7)
    final dayOfWeek = logData['dayOfWeek'] as int?;

    // Extract workoutName (Priority: 1) workoutName from backend, 2) weeklyPlanId.workouts, 3) Fallback)
    String? workoutName = logData['workoutName'] as String?;

    // FALLBACK: Try to extract from weeklyPlanId.workouts array using dayOfWeek
    if ((workoutName == null || workoutName == 'Workout') && logData['weeklyPlanId'] is Map) {
      final weeklyPlanId = logData['weeklyPlanId'] as Map<String, dynamic>;
      final logDayOfWeek = logData['dayOfWeek'] as int?;

      if (logDayOfWeek != null && weeklyPlanId['workouts'] is List) {
        final workouts = weeklyPlanId['workouts'] as List<dynamic>;
        for (final workoutDay in workouts) {
          if (workoutDay is Map<String, dynamic>) {
            final workoutDayOfWeek = workoutDay['dayOfWeek'] as int?;
            if (workoutDayOfWeek == logDayOfWeek) {
              workoutName = workoutDay['name'] as String?;
              break;
            }
          }
        }
      }
    }

    workoutName = workoutName ?? 'Workout';

    // Extract isRestDay
    final isRestDay = logData['isRestDay'] as bool? ?? false;

    // Convert exercises - PRIORITY: 1) planExercises, 2) weeklyPlanId.workouts, 3) completedExercises
    final exercises = <domain.Exercise>[];

    // 1. PRIORITY: planExercises from backend
    if (logData['planExercises'] != null &&
        logData['planExercises'] is List &&
        (logData['planExercises'] as List).isNotEmpty) {
      final planExercises = logData['planExercises'] as List<dynamic>;
      final completedExercises = logData['completedExercises'] as List<dynamic>? ?? [];

      // Create a map of completedExercises by exerciseName for quick lookup
      final completedExercisesMap = <String, Map<String, dynamic>>{};
      for (final completedEx in completedExercises) {
        if (completedEx is Map<String, dynamic>) {
          final exerciseName = completedEx['exerciseName'] as String?;
          if (exerciseName != null) {
            completedExercisesMap[exerciseName] = completedEx;
          }
        }
      }

      for (final exData in planExercises) {
        final exerciseName = exData['name'] as String? ?? 'Exercise';
        final planSets = exData['sets'] as int?;
        final planReps = exData['reps'];

        // Check if we have completed data for this exercise
        final completedEx = completedExercisesMap[exerciseName];
        final hasCompletedData = completedEx != null && isCompleted;

        // Generate sets based on planSets and planReps, or use completedExercises data if available
        List<domain.WorkoutSet> sets = [];
        if (planSets != null && planSets > 0) {
          if (hasCompletedData) {
            // Use completedExercises data to populate sets with actual weight, reps, rpe
            final actualSets = completedEx['actualSets'] as int? ?? planSets;
            final actualReps = completedEx['actualReps'] as List<dynamic>?;
            final weightUsed = (completedEx['weightUsed'] as num?)?.toDouble() ?? 0.0;

            // Generate sets with completed data
            sets = List.generate(actualSets, (index) {
              final reps = actualReps != null && index < actualReps.length
                  ? (actualReps[index] as num?)?.toInt() ?? 0
                  : (planReps is int ? planReps : (planReps is String ? int.tryParse(planReps) ?? 0 : 0));

              return domain.WorkoutSet(
                id: const Uuid().v4(),
                weight: weightUsed,
                reps: reps,
                rpe: null, // RPE not stored in completedExercises
                isCompleted: true, // Mark as completed since we have completed data
              );
            });
          } else {
            // Generate empty sets based on planSets (for non-completed workouts)
            int defaultReps = 0;
            if (planReps != null) {
              if (planReps is int) {
                defaultReps = planReps;
              } else if (planReps is String) {
                final match = RegExp(r'(\d+)').firstMatch(planReps);
                if (match != null) {
                  defaultReps = int.tryParse(match.group(1) ?? '0') ?? 0;
                }
              }
            }

            sets = List.generate(planSets, (index) {
              return domain.WorkoutSet(
                id: const Uuid().v4(),
                weight: 0.0,
                reps: defaultReps,
                rpe: null,
                isCompleted: false,
              );
            });
          }
        }

        exercises.add(
          domain.Exercise(
            id: '',
            name: exerciseName,
            targetMuscle: exData['targetMuscle'] as String? ?? '',
            sets: sets,
            restSeconds: exData['restSeconds'] as int?,
            notes: exData['notes'] as String?,
            planSets: planSets,
            planReps: planReps,
          ),
        );
      }
    } else if (logData['weeklyPlanId'] is Map) {
      // 2. FALLBACK: Extract from weeklyPlanId.workouts
      final weeklyPlanId = logData['weeklyPlanId'] as Map<String, dynamic>;
      final logDayOfWeek = logData['dayOfWeek'] as int?;

      if (logDayOfWeek != null && weeklyPlanId['workouts'] is List) {
        final workouts = weeklyPlanId['workouts'] as List<dynamic>;
        Map<String, dynamic>? planWorkout;
        for (final workoutDay in workouts) {
          if (workoutDay is Map<String, dynamic>) {
            final workoutDayOfWeek = workoutDay['dayOfWeek'] as int?;
            if (workoutDayOfWeek == logDayOfWeek) {
              planWorkout = workoutDay;
              break;
            }
          }
        }

        if (planWorkout != null && planWorkout['exercises'] is List) {
          final planExercises = planWorkout['exercises'] as List<dynamic>;
          for (final exData in planExercises) {
            final planSets = exData['sets'] as int?;
            final planReps = exData['reps'];

            List<domain.WorkoutSet> sets = [];
            if (planSets != null && planSets > 0) {
              int defaultReps = 0;
              if (planReps != null) {
                if (planReps is int) {
                  defaultReps = planReps;
                } else if (planReps is String) {
                  final match = RegExp(r'(\d+)').firstMatch(planReps);
                  if (match != null) {
                    defaultReps = int.tryParse(match.group(1) ?? '0') ?? 0;
                  }
                }
              }

              sets = List.generate(planSets, (index) {
                return domain.WorkoutSet(
                  id: const Uuid().v4(),
                  weight: 0.0,
                  reps: defaultReps,
                  rpe: null,
                  isCompleted: false,
                );
              });
            }

            exercises.add(
              domain.Exercise(
                id: '',
                name: exData['name'] as String? ?? 'Exercise',
                targetMuscle: exData['targetMuscle'] as String? ?? '',
                sets: sets,
                restSeconds: exData['restSeconds'] as int?,
                notes: exData['notes'] as String?,
                planSets: planSets,
                planReps: planReps,
              ),
            );
          }
        }
      }
    }

    // 3. LAST RESORT: completedExercises
    if (exercises.isEmpty && logData['completedExercises'] != null && logData['completedExercises'] is List) {
      final completedExercises = logData['completedExercises'] as List<dynamic>;
      for (final exData in completedExercises) {
        final actualSets = exData['actualSets'] as int?;
        final planSets = actualSets ?? exData['planSets'] as int?;
        final planReps = exData['reps'] ?? exData['planReps'];

        List<domain.WorkoutSet> sets = [];
        if (planSets != null && planSets > 0) {
          int defaultReps = 0;
          if (planReps != null) {
            if (planReps is int) {
              defaultReps = planReps;
            } else if (planReps is String) {
              final match = RegExp(r'(\d+)').firstMatch(planReps);
              if (match != null) {
                defaultReps = int.tryParse(match.group(1) ?? '0') ?? 0;
              }
            }
          }

          sets = List.generate(planSets, (index) {
            return domain.WorkoutSet(
              id: const Uuid().v4(),
              weight: 0.0,
              reps: defaultReps,
              rpe: null,
              isCompleted: false,
            );
          });
        }

        exercises.add(
          domain.Exercise(
            id: '',
            name: exData['exerciseName'] as String? ?? 'Exercise',
            targetMuscle: exData['targetMuscle'] as String? ?? '',
            sets: sets,
            restSeconds: exData['restSeconds'] as int?,
            notes: exData['notes'] as String?,
            planSets: planSets,
            planReps: planReps,
          ),
        );
      }
    }

    return Workout(
      id: serverId,
      serverId: serverId,
      name: workoutName,
      planId: planId,
      scheduledDate: workoutDate,
      dayOfWeek: dayOfWeek,
      isCompleted: isCompleted,
      isMissed: isMissed,
      isRestDay: isRestDay,
      exercises: exercises,
      isDirty: false,
      updatedAt: DateTime.parse(logData['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Parse planReps string to extract default reps value
  /// Examples: "10" -> 10, "8-12" -> 10 (average), "5x5" -> 5, "10, 8, 6" -> 10 (first)
  static int _parsePlanReps(String? planReps) {
    if (planReps == null || planReps.isEmpty) {
      return 10; // Default fallback
    }

    // Try to extract first number from string
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(planReps);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '10') ?? 10;
    }

    return 10; // Default fallback
  }

  /// Save weight or reps value with auto-advance logic
  static void saveValue({
    required String field,
    required int exerciseIndex,
    required int setIndex,
    required String value,
    required Workout workout,
    required WidgetRef ref,
    required ScrollController scrollController,
    required Map<int, GlobalKey> exerciseKeys,
    required Function(String, int, int, String, Workout) showNumpad,
    required Function(int, int, double, Workout) showWeightPicker,
    required Function(int, int, double?, Workout) showRpePicker,
    required Function(int, int, String?, int, Workout) showRepsPicker,
  }) {
    AppHaptic.medium();

    // Parse value
    final numValue = field == 'weight' ? double.tryParse(value) ?? 0.0 : int.tryParse(value) ?? 0;

    // Input validation
    if (field == 'weight' && numValue < 0) {
      debugPrint('[WorkoutStateService] ⚠️ WARNING: Weight cannot be negative: $numValue');
      return;
    }

    if (field == 'reps' && (numValue as int) <= 0) {
      debugPrint('[WorkoutStateService] ⚠️ WARNING: Reps must be greater than 0: $numValue');
      return;
    }

    // Update workout set
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    final updatedSet = WorkoutSet(
      id: set.id,
      weight: field == 'weight' ? numValue as double : set.weight,
      reps: field == 'reps' ? numValue as int : set.reps,
      rpe: set.rpe,
      isCompleted: set.isCompleted,
    );

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);

    // Auto-advance: weight -> reps -> RPE -> next set
    // Call picker directly - callback will check mounted state
    if (field == 'weight') {
      // After weight, open RepsPicker (not numpad)
      // Sačekaj malo da se WeightPicker zatvori pre nego što otvoriš RepsPicker
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          showRepsPicker(exerciseIndex, setIndex, exercise.planReps, set.reps, updatedWorkout);
        } catch (e) {
          debugPrint('[WorkoutStateService] ❌ ERROR calling showRepsPicker(): $e');
        }
      });
    } else if (field == 'reps') {
      // After reps, open RPE
      // Sačekaj malo da se RepsPicker zatvori pre nego što otvoriš RPE picker
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          showRpePicker(exerciseIndex, setIndex, set.rpe, updatedWorkout);
        } catch (e) {
          debugPrint('[WorkoutStateService] ❌ ERROR calling showRpePicker(): $e');
        }
      });
    }
  }

  /// Save RPE value with auto-advance logic
  static void saveRpe({
    required int exerciseIndex,
    required int setIndex,
    required double rpe,
    required Workout workout,
    required WidgetRef ref,
    required ScrollController scrollController,
    required Map<int, GlobalKey> exerciseKeys,
    required Function(String, int, int, String, Workout) showNumpad,
    required Function(int, int, double, Workout) showWeightPicker,
  }) {
    debugPrint(
      '[WorkoutStateService:RPE] Set status before: weight=${workout.exercises[exerciseIndex].sets[setIndex].weight}, reps=${workout.exercises[exerciseIndex].sets[setIndex].reps}, isCompleted=${workout.exercises[exerciseIndex].sets[setIndex].isCompleted}',
    );

    // NOVO: Input validation for RPE
    // RPE should be between 0 and 10, or one of the 3 options (4.5, 6.5, 8.5)
    if (rpe < 0 || rpe > 10) {
      debugPrint('[WorkoutStateService] ⚠️ WARNING: RPE must be between 0 and 10: $rpe');
      // Error handling removed - validation happens at picker level
      return; // Don't update if validation fails
    }

    AppHaptic.medium();

    // Update workout set
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    final updatedSet = WorkoutSet(
      id: set.id,
      weight: set.weight,
      reps: set.reps,
      rpe: rpe,
      isCompleted: true, // NOVO: Auto-check set after RPE input
    );

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);

    // Auto-advance: After RPE, move to next set
    // Call picker directly - callback will check mounted state
    final nextSetIndex = setIndex + 1;
    if (nextSetIndex < exercise.sets.length) {
      // Move to next set in same exercise
      final nextSet = exercise.sets[nextSetIndex];
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          showWeightPicker(exerciseIndex, nextSetIndex, nextSet.weight, updatedWorkout);
        } catch (e) {
          debugPrint('[WorkoutStateService] ❌ ERROR calling showWeightPicker(): $e');
        }
      });
    } else {
      // Move to next exercise
      final nextExerciseIndex = exerciseIndex + 1;
      if (nextExerciseIndex < workout.exercises.length) {
        final nextExercise = workout.exercises[nextExerciseIndex];
        if (nextExercise.sets.isNotEmpty) {
          // Scroll to next exercise before opening picker
          if (scrollController.hasClients) {
            final key = exerciseKeys[nextExerciseIndex];
            if (key != null && key.currentContext != null) {
              Scrollable.ensureVisible(
                key.currentContext!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.1, // Slight offset from top
              );
            }
          }
          // Call picker directly after scroll
          final nextSet = nextExercise.sets[0];
          Future.delayed(const Duration(milliseconds: 200), () {
            try {
              showWeightPicker(nextExerciseIndex, 0, nextSet.weight, updatedWorkout);
            } catch (e) {
              debugPrint('[WorkoutStateService] ❌ ERROR calling showWeightPicker(): $e');
            }
          });
        }
      }
    }
  }

  /// Delete a set from workout
  static WorkoutSet? deleteSet({
    required int exerciseIndex,
    required int setIndex,
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    AppHaptic.medium();

    // Store deleted set for undo
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    // Remove set from exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: List<WorkoutSet>.from(exercise.sets)..removeAt(setIndex),
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    // Update workout
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);

    // Return deleted set for undo functionality
    return set;
  }

  /// Undo set deletion
  static void undoDeleteSet({
    required WorkoutSet deletedSet,
    required int exerciseIndex,
    required int setIndex,
    required Workout workout,
    required WidgetRef ref,
  }) {
    AppHaptic.light();

    final exercise = workout.exercises[exerciseIndex];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets.insert(setIndex, deletedSet);

    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
  }

  /// Check if exercise is completed (ALL sets must be completed)
  static bool isExerciseCompleted(Exercise exercise) {
    // REMOVED: Excessive logging causing rebuild loop when called in build method
    // This method is called frequently, so logging should be minimal
    if (exercise.sets.isEmpty) {
      return false;
    }
    return exercise.sets.every((set) => set.isCompleted);
  }

  /// Toggle set completion
  static void toggleSetCompletion({
    required int exerciseIndex,
    required int setIndex,
    required Workout workout,
    required WidgetRef ref,
  }) {
    AppHaptic.selection();

    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    final newCompletedState = !set.isCompleted;

    // Parse planReps to get default reps value
    final defaultReps = _parsePlanReps(exercise.planReps);

    // NOVO: Auto-populate if marking as completed and values are missing/invalid
    double finalWeight = set.weight;
    int finalReps = set.reps;
    double? finalRpe = set.rpe;

    if (newCompletedState) {
      // Auto-populate if values are missing/invalid
      final needsAutoPopulate = set.weight == 0 || set.reps == 0 || set.rpe == null;

      if (needsAutoPopulate) {
        // Set default values when marking as completed
        // weight=5.0 (first option from WeightPicker), RPE=6.5 (Ok - middle option from RpePicker)
        finalWeight = set.weight == 0 ? 5.0 : (set.weight < 0 ? 5.0 : set.weight);
        finalReps = set.reps == 0 ? defaultReps : (set.reps <= 0 ? defaultReps : set.reps);
        final currentRpe = set.rpe ?? 0.0;
        finalRpe = currentRpe == 0 ? 6.5 : (currentRpe < 0 || currentRpe > 10 ? 6.5 : currentRpe);
      }
    }

    // Create updated set with new completion state and auto-populated values
    final updatedSet = WorkoutSet(
      id: set.id,
      weight: finalWeight,
      reps: finalReps,
      rpe: finalRpe,
      isCompleted: newCompletedState,
    );

    // Update sets list
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;

    // Create updated exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    // Create updated workout
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
  }

  /// Toggle exercise completion - toggles ALL sets in the exercise
  static void toggleExerciseCompletion({
    required int exerciseIndex,
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
    required DateTime? workoutStartTime,
    required Function(bool) onFastCompletion,
  }) {
    AppHaptic.selection();

    final exercise = workout.exercises[exerciseIndex];
    final isCurrentlyCompleted = isExerciseCompleted(exercise);
    final newCompletedState = !isCurrentlyCompleted;

    debugPrint('[WorkoutStateService:Toggle] ═══════════════════════════════════════');
    debugPrint('[WorkoutStateService:Toggle] Exercise $exerciseIndex toggle initiated');
    debugPrint('[WorkoutStateService:Toggle] Exercise name: "${exercise.name}"');
    debugPrint('[WorkoutStateService:Toggle] Current state: $isCurrentlyCompleted');
    debugPrint('[WorkoutStateService:Toggle] New state: $newCompletedState');
    debugPrint('[WorkoutStateService:Toggle] Updating ${exercise.sets.length} sets to $newCompletedState');

    // NOVO: Parse planReps to get default reps value
    final defaultReps = _parsePlanReps(exercise.planReps);
    debugPrint('[WorkoutStateService] Default reps from planReps "$exercise.planReps": $defaultReps');

    // Create updated sets with new completion state
    // NOVO: If marking as completed, set default values (weight=5.0, reps=parsed planReps, RPE=6.5)
    final updatedSets = exercise.sets.asMap().entries.map((entry) {
      final setIndex = entry.key;
      final set = entry.value;

      debugPrint(
        '[WorkoutStateService:AutoPopulate] Set $setIndex - weight: ${set.weight}, reps: ${set.reps}, rpe: ${set.rpe}, isCompleted: ${set.isCompleted}',
      );

      if (newCompletedState) {
        // NOVO: Auto-populate if set is not completed OR if values are missing/invalid
        final needsAutoPopulate = !set.isCompleted || set.weight == 0 || set.reps == 0 || set.rpe == null;
        debugPrint(
          '[WorkoutStateService:AutoPopulate] Set $setIndex - needsAutoPopulate: $needsAutoPopulate (newCompletedState: $newCompletedState, set.isCompleted: ${set.isCompleted}, weight==0: ${set.weight == 0}, reps==0: ${set.reps == 0}, rpe==null: ${set.rpe == null})',
        );

        if (needsAutoPopulate) {
          // Set default values when marking as completed
          // NOVO: Ensure default values pass validation (weight >= 0, reps > 0, RPE 0-10)
          // weight=5.0 (first option from WeightPicker), RPE=6.5 (Ok - middle option from RpePicker)
          final safeWeight = set.weight == 0 ? 5.0 : (set.weight < 0 ? 5.0 : set.weight);
          final safeReps = set.reps == 0 ? defaultReps : (set.reps <= 0 ? defaultReps : set.reps);
          final currentRpe = set.rpe ?? 0.0;
          final safeRpe = currentRpe == 0 ? 6.5 : (currentRpe < 0 || currentRpe > 10 ? 6.5 : currentRpe);

          debugPrint(
            '[WorkoutStateService:AutoPopulate] Set $setIndex - AUTO-POPULATING: weight=$safeWeight, reps=$safeReps, rpe=$safeRpe',
          );

          return WorkoutSet(
            id: set.id,
            weight: safeWeight, // Default weight=5.0 if 0 or negative (first option from WeightPicker)
            reps: safeReps, // Default reps=parsed planReps if 0 or negative
            rpe: safeRpe, // Default RPE=6.5 if 0 or invalid (Ok - middle option from RpePicker)
            isCompleted: newCompletedState,
          );
        } else {
          debugPrint(
            '[WorkoutStateService:AutoPopulate] Set $setIndex - Already has values, keeping existing: weight=${set.weight}, reps=${set.reps}, rpe=${set.rpe}',
          );
        }
      }

      return WorkoutSet(id: set.id, weight: set.weight, reps: set.reps, rpe: set.rpe, isCompleted: newCompletedState);
    }).toList();

    // Create updated exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
      category: exercise.category,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      restSeconds: exercise.restSeconds,
      notes: exercise.notes,
      planSets: exercise.planSets,
      planReps: exercise.planReps,
    );

    // Create updated workout
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      isMissed: workout.isMissed,
      isRestDay: workout.isRestDay,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );

    // Fast completion validation (only for first exercise, only once)
    if (exerciseIndex == 0 && newCompletedState == true && workoutStartTime != null) {
      final duration = DateTime.now().difference(workoutStartTime);
      debugPrint('[WorkoutStateService] Workout duration: ${duration.inSeconds}s - Threshold: 30s');

      if (duration.inSeconds < 30) {
        debugPrint('[WorkoutStateService] Fast completion detected');
        onFastCompletion(true);
      }
    }

    try {
      // Optimistic UI update + save to repository
      ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
      debugPrint('[WorkoutStateService] Isar DB update SUCCESS');
    } catch (e) {
      // Rollback on error - revert to original state
      debugPrint('[WorkoutStateService] ERROR - Rollback initiated: $e');

      // Revert the workout update
      ref.read(workoutControllerProvider.notifier).updateWorkout(workout);

      // Show error message
      if (context.mounted) {
        ErrorHandler.showError(context, e, duration: const Duration(seconds: 4));
      }
    }
  }

  /// Finish workout - mark as completed with API call
  static Future<void> finishWorkout({
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
    required ConfettiController confettiController,
  }) async {
    AppHaptic.heavy();

    try {
      // Lock mehanizam - proveriti da li workout već sync-uje
      if (workout.isSyncing) {
        debugPrint('[WorkoutStateService] ⚠️ WARNING: Workout is already syncing, skipping to prevent race condition');
        if (context.mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ErrorHandler.showError(
                context,
                Exception('Workout is already being synced. Please wait.'),
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
        return;
      }

      // Migration logika - pokušati da izvuče dayOfWeek ako nedostaje
      Workout workoutWithDayOfWeek = workout;
      bool migrationFailedDueToNetwork = false;
      if (workout.dayOfWeek == null) {
        try {
          final migratedDayOfWeek = await ref.read(workoutControllerProvider.notifier).migrateDayOfWeek(workout);
          if (migratedDayOfWeek != null) {
            workoutWithDayOfWeek = _createUpdatedWorkout(originalWorkout: workout, dayOfWeek: migratedDayOfWeek);
            // Update workout in repository with migrated dayOfWeek
            await ref.read(workoutControllerProvider.notifier).updateWorkout(workoutWithDayOfWeek);
          } else {
            debugPrint('[WorkoutStateService] ⚠️ WARNING: Migration failed, dayOfWeek is still null');
            migrationFailedDueToNetwork = true; // Assume network error if migration fails
          }
        } catch (e) {
          debugPrint('[WorkoutStateService] ⚠️ WARNING: Migration exception: $e');
          migrationFailedDueToNetwork = true;
        }
      }

      // Migration logika za planId - pokušati da izvuče planId ako nedostaje
      Workout workoutWithPlanId = workoutWithDayOfWeek;
      if (workoutWithPlanId.planId == null) {
        try {
          final migratedPlanId = await ref.read(workoutControllerProvider.notifier).migratePlanId(workoutWithDayOfWeek);
          if (migratedPlanId != null) {
            workoutWithPlanId = _createUpdatedWorkout(originalWorkout: workoutWithPlanId, planId: migratedPlanId);
            // Update workout in repository with migrated planId
            await ref.read(workoutControllerProvider.notifier).updateWorkout(workoutWithPlanId);
          } else {
            debugPrint('[WorkoutStateService] ⚠️ WARNING: Migration failed, planId is still null');
            migrationFailedDueToNetwork = true; // Assume network error if migration fails
          }
        } catch (e) {
          debugPrint('[WorkoutStateService] ⚠️ WARNING: Migration exception: $e');
          migrationFailedDueToNetwork = true;
        }
      }

      // Validate required fields before API call
      // If migration failed due to network error, allow offline finish
      if (workoutWithPlanId.planId == null || workoutWithPlanId.dayOfWeek == null) {
        if (migrationFailedDueToNetwork) {
          // Network error during migration - allow offline finish
          debugPrint('[WorkoutStateService] ⚠️ planId/dayOfWeek is null due to network error, allowing offline finish');

          final offlineWorkout = _createUpdatedWorkout(
            originalWorkout: workoutWithPlanId,
            isCompleted: true, // Mark as completed locally
            isDirty: true, // Mark as dirty for sync manager
            isSyncing: false, // Reset lock flag
          );

          await ref.read(workoutControllerProvider.notifier).updateWorkout(offlineWorkout);

          if (context.mounted) {
            ErrorHandler.showError(
              context,
              'Workout saved locally. Will sync when online.',
              duration: const Duration(seconds: 4),
            );

            // Navigate to calendar even in offline mode
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted) {
                context.go('/calendar');
              }
            });
          }

          return;
        } else {
          // Not a network error - show error dialog
          if (workoutWithPlanId.planId == null) {
            debugPrint('[WorkoutStateService] ❌ ERROR: planId is null, cannot log workout');
            if (context.mounted) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  ErrorHandler.showErrorDialog(
                    context,
                    Exception('Workout plan ID is missing. Please sync with server.'),
                    customTitle: 'Cannot Finish Workout',
                  );
                }
              });
            }
            throw Exception('Cannot finish workout: planId is null');
          }

          if (workoutWithPlanId.dayOfWeek == null) {
            debugPrint('[WorkoutStateService] ❌ ERROR: dayOfWeek is null, cannot log workout');
            if (context.mounted) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  ErrorHandler.showErrorDialog(
                    context,
                    Exception('Workout day of week is missing. Please sync with server.'),
                    customTitle: 'Cannot Finish Workout',
                  );
                }
              });
            }
            throw Exception('Cannot finish workout: dayOfWeek is null');
          }
        }
      }

      // NOVO: Ako je workout već označen kao missed, resetuj missed status pre finish-a
      // Korisnik može da finish-uje workout čak i ako je greškom označen kao missed
      if (workoutWithPlanId.isMissed == true) {
        debugPrint(
          '[WorkoutStateService:Finish] ⚠️ WARNING: Workout was marked as missed, resetting missed status before finish',
        );
        // Reset missed status - workout will be marked as completed instead
        workoutWithPlanId = _createUpdatedWorkout(originalWorkout: workoutWithPlanId, isMissed: false);
      }

      // NOVO: Validacija - proveriti da li su sve vežbe checkirane (skip za rest day)
      if (workoutWithPlanId.isRestDay == true) {
        debugPrint('[WorkoutStateService:Finish] ⚠️ Rest day workout - skipping exercise validation');
      } else {
        debugPrint('[WorkoutStateService:Finish] Validating all exercises are completed...');
        final allExercises = workoutWithPlanId.exercises;
        final incompleteExercises = <String>[];

        for (int i = 0; i < allExercises.length; i++) {
          final exercise = allExercises[i];
          final exerciseIsCompleted = isExerciseCompleted(exercise);
          final completedSetsCount = exercise.sets.where((s) => s.isCompleted).length;
          debugPrint(
            '[WorkoutStateService:Finish] Exercise ${i + 1}/${allExercises.length}: "${exercise.name}" - $completedSetsCount/${exercise.sets.length} sets completed - Overall: $exerciseIsCompleted',
          );

          if (!exerciseIsCompleted) {
            incompleteExercises.add(exercise.name);
          }
        }

        if (incompleteExercises.isNotEmpty) {
          debugPrint(
            '[WorkoutStateService:Finish] ❌❌❌ ERROR: Cannot finish workout - ${incompleteExercises.length} exercise(s) not completed: ${incompleteExercises.join(", ")} ❌❌❌',
          );
          if (context.mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ErrorHandler.showErrorDialog(
                  context,
                  Exception('Cannot finish workout. Please complete all exercises:\n${incompleteExercises.join("\n")}'),
                  customTitle: 'Incomplete Workout',
                );
              }
            });
          }
          // Throw exception instead of return to prevent false success message
          throw Exception('Cannot finish workout: ${incompleteExercises.length} exercise(s) not completed');
        }

        debugPrint('[WorkoutStateService:Finish] ✅ All exercises completed - proceeding with finish');
      }

      // 1. Convert exercises to completedExercises format
      debugPrint('[WorkoutStateService:Finish] Converting exercises to completedExercises format...');
      final completedExercises = workoutWithPlanId.exercises.where((ex) => ex.sets.any((set) => set.isCompleted)).map((
        ex,
      ) {
        final completedSets = ex.sets.where((s) => s.isCompleted).toList();
        final weightUsed = completedSets.isNotEmpty ? completedSets.first.weight : null;

        // Log warning if weights differ across sets
        if (completedSets.length > 1) {
          final uniqueWeights = completedSets.map((s) => s.weight).toSet();
          if (uniqueWeights.length > 1) {
            debugPrint(
              '[WorkoutStateService:Finish] WARNING: Exercise ${ex.name} has different weights across sets: $uniqueWeights, using first: $weightUsed',
            );
          }
        }

        return {
          'exerciseName': ex.name,
          'actualSets': completedSets.length,
          'actualReps': completedSets.map((s) => s.reps).toList(),
          'weightUsed': weightUsed,
        };
      }).toList();

      debugPrint('[WorkoutStateService:Finish] Converted ${completedExercises.length} completed exercises');

      // 2. Set isSyncing=true BEFORE API call (lock mechanism)
      debugPrint('[WorkoutStateService:Finish] Setting isSyncing=true to prevent race condition');
      final lockedWorkout = Workout(
        id: workoutWithPlanId.id,
        serverId: workoutWithPlanId.serverId,
        name: workoutWithPlanId.name,
        planId: workoutWithPlanId.planId,
        scheduledDate: workoutWithPlanId.scheduledDate,
        dayOfWeek: workoutWithPlanId.dayOfWeek,
        isCompleted: workoutWithPlanId.isCompleted,
        isMissed: workoutWithPlanId.isMissed,
        isRestDay: workoutWithPlanId.isRestDay,
        exercises: workoutWithPlanId.exercises,
        isDirty: workoutWithPlanId.isDirty,
        isSyncing: true, // NOVO: Set lock flag
        updatedAt: DateTime.now(),
      );
      await ref.read(workoutControllerProvider.notifier).updateWorkout(lockedWorkout);

      // 2. Call logWorkout API FIRST (before local update) with retry logic
      debugPrint('[WorkoutStateService:Finish] Calling logWorkout API...');

      // NOVO: Use Riverpod provider for dependency injection
      final dataSource = ref.read(remoteDataSourceProvider);

      // Use today's date for workout completion (backend doesn't allow future dates)
      // If scheduledDate is in the future, use today instead
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final scheduledDateOnly = DateTime(
        workoutWithPlanId.scheduledDate.year,
        workoutWithPlanId.scheduledDate.month,
        workoutWithPlanId.scheduledDate.day,
      );

      // Use today if scheduledDate is in the future, otherwise use scheduledDate
      final workoutDateToSend = scheduledDateOnly.isAfter(todayDateOnly) ? todayDateOnly : scheduledDateOnly;

      debugPrint(
        '[WorkoutStateService:Finish] Workout scheduledDate: ${workoutWithPlanId.scheduledDate.toIso8601String()}, '
        'Using workoutDate: ${workoutDateToSend.toIso8601String()} (today: ${todayDateOnly.toIso8601String()})',
      );

      // NOVO: Validate dayOfWeek before sending
      final dayOfWeekToSend = workoutWithPlanId.dayOfWeek!;
      debugPrint('[WorkoutStateService:Finish] ═══════════════════════════════════════');
      debugPrint('[WorkoutStateService:Finish] Preparing API request:');
      debugPrint('[WorkoutStateService:Finish]   - workoutDate: ${workoutDateToSend.toIso8601String()}');
      debugPrint('[WorkoutStateService:Finish]   - weeklyPlanId: ${workoutWithPlanId.planId}');
      debugPrint('[WorkoutStateService:Finish]   - dayOfWeek: $dayOfWeekToSend (plan day index 1-7)');
      debugPrint('[WorkoutStateService:Finish]   - workout.isRestDay: ${workoutWithPlanId.isRestDay}');
      debugPrint('[WorkoutStateService:Finish]   - workout.name: ${workoutWithPlanId.name}');

      final logData = {
        'workoutDate': workoutDateToSend.toIso8601String(),
        'weeklyPlanId': workoutWithPlanId.planId!, // Must exist (validated above)
        'dayOfWeek': dayOfWeekToSend, // Must exist (validated above) - Plan day index (1-7)
        'completedExercises': completedExercises,
        'isCompleted': true,
        'completedAt': DateTime.now().toIso8601String(),
      };

      debugPrint('[WorkoutStateService:Finish] API Request payload: $logData');
      debugPrint('[WorkoutStateService:Finish] ═══════════════════════════════════════');

      // NOVO: Retry logic (1-2 retries for network errors)
      Map<String, dynamic>? response;
      int maxRetries = 2;
      int retryCount = 0;

      while (retryCount <= maxRetries) {
        try {
          // NOVO: Timeout handling (30 seconds)
          response = await dataSource
              .logWorkout(logData)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw Exception('Request timeout after 30 seconds');
                },
              );
          debugPrint('[WorkoutStateService:Finish] API Response: $response');
          break; // Success, exit retry loop
        } on DioException catch (e) {
          final isRetryable =
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError;

          if (isRetryable && retryCount < maxRetries) {
            retryCount++;
            debugPrint(
              '[WorkoutStateService:Finish] Network error (retryable), retrying ($retryCount/$maxRetries): $e',
            );
            await Future.delayed(Duration(seconds: retryCount)); // Exponential backoff
            continue;
          } else {
            // NOVO: Offline detection - mark as dirty for sync manager
            debugPrint('[WorkoutStateService:Finish] Network error (non-retryable or max retries reached): $e');
            debugPrint('[WorkoutStateService:Finish] Marking workout as dirty for sync manager (offline queue)');

            final offlineWorkout = _createUpdatedWorkout(
              originalWorkout: workoutWithPlanId,
              isCompleted: true, // Mark as completed locally
              isDirty: true, // Mark as dirty for sync manager
              isSyncing: false, // Reset lock flag
            );

            await ref.read(workoutControllerProvider.notifier).updateWorkout(offlineWorkout);

            if (context.mounted) {
              ErrorHandler.showError(
                context,
                'Workout saved locally. Will sync when online.',
                duration: const Duration(seconds: 4),
              );

              // Navigate to calendar even in offline mode
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted) {
                  context.go('/calendar');
                }
              });
            }

            debugPrint('[WorkoutStateService:Finish] ✅ Workout saved locally (offline mode)');
            debugPrint('[WorkoutStateService:Finish] ═══════════════════════════════════════');
            return;
          }
        } catch (e) {
          // NOVO: Check if error is a REAL network error or backend validation error
          final errorMessage = e.toString();
          final errorMessageLower = errorMessage.toLowerCase();

          // Real network errors (no response from server)
          final isRealNetworkError =
              errorMessageLower.contains('network error:') ||
              (errorMessageLower.contains('connection') &&
                  (errorMessageLower.contains('timeout') || errorMessageLower.contains('failed'))) ||
              errorMessageLower.contains('socket') ||
              errorMessageLower.contains('connection refused') ||
              errorMessageLower.contains('connection reset');

          // Backend validation errors (server responded with error)
          final isBackendError =
              errorMessageLower.contains('backend error') ||
              errorMessageLower.contains('validation') ||
              errorMessageLower.contains('bad request') ||
              errorMessageLower.contains('unauthorized') ||
              errorMessageLower.contains('forbidden') ||
              errorMessageLower.contains('not found') ||
              errorMessageLower.contains('internal server error');

          debugPrint('[WorkoutStateService:Finish] Error caught: $e');
          debugPrint('[WorkoutStateService:Finish] Error type analysis:');
          debugPrint('[WorkoutStateService:Finish]   - isRealNetworkError: $isRealNetworkError');
          debugPrint('[WorkoutStateService:Finish]   - isBackendError: $isBackendError');

          if (isRealNetworkError && !isBackendError) {
            // Real network error - save locally for offline sync
            debugPrint('[WorkoutStateService:Finish] ✅ Real network error detected - saving locally for offline sync');
            debugPrint('[WorkoutStateService:Finish] Marking workout as dirty for sync manager (offline queue)');

            final offlineWorkout = _createUpdatedWorkout(
              originalWorkout: workoutWithPlanId,
              isCompleted: true, // Mark as completed locally
              isDirty: true, // Mark as dirty for sync manager
              isSyncing: false, // Reset lock flag
            );

            await ref.read(workoutControllerProvider.notifier).updateWorkout(offlineWorkout);

            if (context.mounted) {
              ErrorHandler.showError(
                context,
                'Workout saved locally. Will sync when online.',
                duration: const Duration(seconds: 4),
              );

              // Navigate to calendar even in offline mode
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted) {
                  context.go('/calendar');
                }
              });
            }

            debugPrint('[WorkoutStateService:Finish] ✅ Workout saved locally (offline mode)');
            debugPrint('[WorkoutStateService:Finish] ═══════════════════════════════════════');
            return;
          } else {
            // Backend validation error or other non-network error
            debugPrint('[WorkoutStateService:Finish] ❌ Backend validation/error detected - NOT saving locally');
            debugPrint('[WorkoutStateService:Finish] Error: $e');
            // Error will be caught by outer catch block and shown to user
            rethrow;
          }
        }
      }

      // Validate response structure
      if (response == null || response.isEmpty) {
        throw Exception(
          'Invalid response from server. The server returned an empty or invalid response. Please try again.',
        );
      }

      // Extract serverId from response if available
      final serverId = response['_id']?.toString() ?? response['id']?.toString();
      if (serverId != null) {
        debugPrint('[WorkoutStateService:Finish] Received serverId from API: $serverId');
      }

      // 3. Only after successful API call, mark workout as completed locally
      debugPrint('[WorkoutStateService:Finish] API call successful, updating local workout...');
      debugPrint('[WorkoutStateService:Finish:DataPersistence] ═══════════════════════════════════════');
      debugPrint('[WorkoutStateService:Finish:DataPersistence] Workout state BEFORE local update (after API success):');
      debugPrint('[WorkoutStateService:Finish:DataPersistence] Workout isCompleted: ${workoutWithPlanId.isCompleted}');
      debugPrint(
        '[WorkoutStateService:Finish:DataPersistence] Workout has ${workoutWithPlanId.exercises.length} exercises',
      );
      for (int exIndex = 0; exIndex < workoutWithPlanId.exercises.length; exIndex++) {
        final exercise = workoutWithPlanId.exercises[exIndex];
        debugPrint(
          '[WorkoutStateService:Finish:DataPersistence] Exercise $exIndex: "${exercise.name}" has ${exercise.sets.length} sets',
        );
        for (int setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
          final set = exercise.sets[setIndex];
          debugPrint(
            '[WorkoutStateService:Finish:DataPersistence] Set $setIndex: isCompleted=${set.isCompleted}, weight=${set.weight}, reps=${set.reps}, rpe=${set.rpe}',
          );
        }
      }
      debugPrint('[WorkoutStateService:Finish:DataPersistence] ═══════════════════════════════════════');

      final updatedWorkout = _createUpdatedWorkout(
        originalWorkout: workoutWithPlanId,
        serverId: serverId ?? workoutWithPlanId.serverId, // Use serverId from response if available
        isCompleted: true,
        isMissed: false,
        isDirty: false, // Mark as not dirty since we just synced
        isSyncing: false, // NOVO: Reset lock flag after successful sync
      );

      // NOVO: Log workout state AFTER creating updated workout (before saving)
      debugPrint('[WorkoutStateService:Finish:DataPersistence] ═══════════════════════════════════════');
      debugPrint(
        '[WorkoutStateService:Finish:DataPersistence] Workout state AFTER creating updated workout (before saving):',
      );
      debugPrint('[WorkoutStateService:Finish:DataPersistence] Workout isCompleted: ${updatedWorkout.isCompleted}');
      debugPrint(
        '[WorkoutStateService:Finish:DataPersistence] Workout has ${updatedWorkout.exercises.length} exercises',
      );
      for (int exIndex = 0; exIndex < updatedWorkout.exercises.length; exIndex++) {
        final exercise = updatedWorkout.exercises[exIndex];
        debugPrint(
          '[WorkoutStateService:Finish:DataPersistence] Exercise $exIndex: "${exercise.name}" has ${exercise.sets.length} sets',
        );
        for (int setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
          final set = exercise.sets[setIndex];
          debugPrint(
            '[WorkoutStateService:Finish:DataPersistence] Set $setIndex: isCompleted=${set.isCompleted}, weight=${set.weight}, reps=${set.reps}, rpe=${set.rpe}',
          );
        }
      }
      debugPrint('[WorkoutStateService:Finish:DataPersistence] ═══════════════════════════════════════');

      // NOVO: Retry local update with exponential backoff (partial success scenario)
      final localUpdateSuccess = await _retryLocalUpdate(updatedWorkout: updatedWorkout, ref: ref, maxRetries: 2);

      if (localUpdateSuccess) {
        debugPrint('[WorkoutStateService:Finish] Local workout updated - isCompleted: true, isDirty: false');
        debugPrint('[WorkoutStateService:Finish:DataPersistence] ✅ Workout saved to database with all set data');
      } else {
        debugPrint('[WorkoutStateService:Finish] ⚠️ WARNING: API call succeeded but local update failed after retries');
        debugPrint('[WorkoutStateService:Finish] Workout is synced on backend but local state might be inconsistent');
        if (context.mounted) {
          ErrorHandler.showError(
            context,
            'Workout logged on server, but local update failed. Please refresh the app to see the updated status.',
            duration: const Duration(seconds: 5),
          );
        }
      }

      // 4. Show confetti and success message
      confettiController.play();
      if (context.mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workout completed and logged!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate to calendar after short delay
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted) {
                debugPrint('[WorkoutStateService:Finish] Navigating to /calendar');
                context.go('/calendar');
              }
            });
          }
        });
      }

      // After successful API call and local update
      // OPTIMIZATION: Use the workout log returned from API for optimistic update
      // This avoids duplicate API call and prevents UI flickering
      try {
        debugPrint('[WorkoutStateService:Finish] Refreshing workout logs from server...');

        // VALIDATION: Check if API response contains valid workout log data
        // Response should be a Map with workout log fields (already validated as non-null and non-empty above)
        Map<String, dynamic> workoutLogData = response;

        // Validate that it has required fields
        Map<String, dynamic>? validatedWorkoutLogData = workoutLogData;
        if (workoutLogData['_id'] == null && workoutLogData['id'] == null) {
          debugPrint('[WorkoutStateService:Finish] ⚠️ Response missing ID field, falling back to full reload');
          validatedWorkoutLogData = null;
        }

        // OPTIMIZATION: Check if API response contains the updated workout log
        // If yes, use it for optimistic update instead of full reload
        if (validatedWorkoutLogData != null) {
          try {
            // Convert WorkoutLog from backend to Workout entity
            final updatedWorkout = _convertWorkoutLogToWorkout(validatedWorkoutLogData);

            // Use optimistic update (no API call, no flickering)
            await ref.read(workoutControllerProvider.notifier).refreshWorkouts(updatedWorkout: updatedWorkout);
            debugPrint('[WorkoutStateService:Finish] ✅ Workout logs optimistically updated');
          } catch (convertError) {
            debugPrint('[WorkoutStateService:Finish] ⚠️ Failed to convert workout log: $convertError');
            debugPrint('[WorkoutStateService:Finish] → Falling back to full reload');
            // Fallback: Full reload if conversion fails
            await ref.read(workoutControllerProvider.notifier).refreshWorkouts();
            debugPrint('[WorkoutStateService:Finish] ✅ Workout logs refreshed from server (full reload)');
          }
        } else {
          // Fallback: Full reload if API didn't return workout log or response is invalid
          await ref.read(workoutControllerProvider.notifier).refreshWorkouts();
          debugPrint('[WorkoutStateService:Finish] ✅ Workout logs refreshed from server (full reload)');
        }
      } catch (e) {
        debugPrint('[WorkoutStateService:Finish] ⚠️ Failed to refresh workout logs: $e');
        // Don't throw - workout is already logged, refresh is just for consistency
        // Workout state is already updated locally, so this is non-critical
      }

      debugPrint('[WorkoutStateService:Finish] ✅ Workout finished successfully');
      debugPrint('[WorkoutStateService:Finish] ═══════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('[WorkoutStateService:Finish] ERROR: $e');
      debugPrint('[WorkoutStateService:Finish] Stack trace: $stackTrace');

      // Error occurred - workout is NOT marked as completed
      // Mark as dirty so sync manager can retry later
      final errorWorkout = Workout(
        id: workout.id,
        serverId: workout.serverId,
        name: workout.name,
        planId: workout.planId,
        scheduledDate: workout.scheduledDate,
        dayOfWeek: workout.dayOfWeek,
        isCompleted: false, // Keep as false since API failed
        isMissed: workout.isMissed,
        isRestDay: workout.isRestDay,
        exercises: workout.exercises,
        isDirty: true, // Mark as dirty for sync manager
        isSyncing: false, // NOVO: Reset lock flag on error
        updatedAt: DateTime.now(),
      );

      try {
        await ref.read(workoutControllerProvider.notifier).updateWorkout(errorWorkout);
      } catch (updateError) {
        debugPrint('[WorkoutStateService:Finish] ERROR updating workout after failure: $updateError');
      }

      if (context.mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ErrorHandler.showErrorDialog(context, e, customTitle: 'Failed to Finish Workout');
          }
        });
      }

      debugPrint('[WorkoutStateService:Finish] ❌ Workout finish failed, marked as dirty for sync');
      debugPrint('[WorkoutStateService:Finish] ═══════════════════════════════════════');
    }
  }

  /// Mark workout as missed (give up)
  static Future<void> markAsMissed({
    required Workout workout,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    AppHaptic.medium();

    try {
      // Lock mehanizam - proveriti da li workout već sync-uje
      if (workout.isSyncing) {
        debugPrint('[WorkoutStateService] ⚠️ WARNING: Workout is already syncing, skipping to prevent race condition');
        if (context.mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ErrorHandler.showError(
                context,
                Exception('Workout is already being synced. Please wait.'),
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
        return;
      }

      // Initialize apiSuccess variable (used later for isDirty flag)
      bool apiSuccess = false;
      dynamic updateResponse; // Store backend response for workout refresh

      // 1. If workout was already logged, update via updateWorkoutLog API with retry logic
      if (workout.serverId != null) {
        // Use Riverpod provider for dependency injection
        final dataSource = ref.read(remoteDataSourceProvider);

        // Retry logic (1-2 retries for network errors)
        int maxRetries = 2;
        int retryCount = 0;
        while (retryCount <= maxRetries) {
          try {
            // Timeout handling (30 seconds)
            updateResponse = await dataSource
                .updateWorkoutLog(workout.serverId!, {'isMissed': true, 'isCompleted': false})
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    throw Exception('Request timeout after 30 seconds');
                  },
                );

            apiSuccess = true;
            break; // Success, exit retry loop
          } on DioException catch (e) {
            final isRetryable =
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.connectionError;

            if (isRetryable && retryCount < maxRetries) {
              retryCount++;
              await Future.delayed(Duration(seconds: retryCount)); // Exponential backoff
              continue;
            } else {
              // Offline detection - mark as dirty for sync manager
              debugPrint('[WorkoutStateService] ⚠️ Network error (non-retryable or max retries reached): $e');
              apiSuccess = false;
              break;
            }
          } catch (e) {
            // Non-network errors (timeout, validation, etc.)
            debugPrint('[WorkoutStateService] ⚠️ Error: $e');
            apiSuccess = false;
            break;
          }
        }
      }

      // 2. Update local workout: use backend response if available, otherwise create updated workout
      // Backend handles resetting completedExercises when isMissed=true (professional solution)
      Workout updatedWorkout;
      if (apiSuccess && updateResponse != null) {
        // Use backend response (contains reset completedExercises)
        try {
          updatedWorkout = _convertWorkoutLogToWorkout(updateResponse);
        } catch (convertError) {
          debugPrint('[WorkoutStateService] ⚠️ Failed to convert backend response: $convertError');
          // Fallback: Create updated workout locally
          updatedWorkout = _createUpdatedWorkout(
            originalWorkout: workout,
            isCompleted: false,
            isMissed: true,
            isDirty: false,
            isSyncing: false,
          );
        }
      } else {
        // Offline or API failed: Create updated workout locally
        updatedWorkout = _createUpdatedWorkout(
          originalWorkout: workout,
          isCompleted: false,
          isMissed: true,
          isDirty: workout.serverId == null || !apiSuccess,
          isSyncing: false,
        );
      }

      // Retry local update with exponential backoff (partial success scenario)
      final localUpdateSuccess = await _retryLocalUpdate(updatedWorkout: updatedWorkout, ref: ref, maxRetries: 2);

      if (!localUpdateSuccess) {
        debugPrint('[WorkoutStateService] ⚠️ WARNING: Local update failed after retries');
        if (context.mounted) {
          ErrorHandler.showError(
            context,
            'Workout marked as missed on server, but local update failed. Please refresh the app to see the updated status.',
            duration: const Duration(seconds: 5),
          );
        }
      }

      // 3. Show message
      if (context.mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  workout.serverId == null || !apiSuccess
                      ? 'Workout marked as missed. Will sync when online.'
                      : 'Workout marked as missed',
                ),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate back to calendar
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                context.go('/calendar');
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[WorkoutStateService] ❌ ERROR marking workout as missed: $e');

      if (context.mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ErrorHandler.showErrorDialog(context, e, customTitle: 'Failed to Mark as Missed');
          }
        });
      }

      debugPrint('[WorkoutStateService:Missed] ❌ Failed to mark workout as missed');
      debugPrint('[WorkoutStateService:Missed] ═══════════════════════════════════════');
    }
  }
}
