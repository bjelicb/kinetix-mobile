import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/pages/workout/services/workout_timer_service.dart';
import '../../presentation/pages/workout/services/workout_validation_service.dart';
import '../../presentation/pages/workout/services/workout_input_service.dart';
import '../../presentation/pages/workout/services/workout_state_service.dart';
import '../../presentation/widgets/workout/workout_header_widget.dart';
import '../../presentation/widgets/workout/exercise_card_widget.dart';
import '../../presentation/widgets/workout/finish_workout_button_widget.dart';
import '../../presentation/widgets/workout/check_in_required_widget.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';

class WorkoutRunnerPage extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutRunnerPage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutRunnerPage> createState() => _WorkoutRunnerPageState();
}

class _WorkoutRunnerPageState extends ConsumerState<WorkoutRunnerPage> {
  late WorkoutTimerService _timerService;
  ConfettiController? _confettiController;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _exerciseKeys = {};

  bool _hasValidCheckIn = false;
  bool _checkingCheckIn = true;
  DateTime? _workoutStartTime;
  bool _hasShownFastCompletionMessage = false;
  final Set<int> _loadingExercises = {};
  final Set<String> _loadingSets = {}; // Format: "exerciseIndex_setIndex"

  WorkoutSet? _deletedSet;
  int? _deletedExerciseIndex;
  int? _deletedSetIndex;

  @override
  void initState() {
    super.initState();
    _timerService = WorkoutTimerService();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _workoutStartTime = DateTime.now();
    _timerService.startTimer(() {
      if (mounted) setState(() {});
    });
    _checkCheckInStatus();
  }

  Future<void> _checkCheckInStatus() async {
    final result = await WorkoutValidationService.checkCheckInStatus();

    if (!mounted) {
      return;
    }

    setState(() {
      _hasValidCheckIn = result.hasValidCheckIn;
      _checkingCheckIn = false;
    });

    if (!_hasValidCheckIn && mounted) {
      debugPrint('[WorkoutRunner] ⚠️ NO VALID CHECK-IN - Showing check-in required');
      WorkoutValidationService.showCheckInRequired(context);
    }
  }

  void _showNumpad(String field, int exerciseIndex, int setIndex, String initialValue, Workout workout) {
    WorkoutInputService.showNumpad(
      context: context,
      field: field,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      initialValue: initialValue,
      workout: workout,
      onValueSaved: (field, exerciseIndex, setIndex, value, workout) {
        _saveValue(field, exerciseIndex, setIndex, value, workout);
      },
    );
  }

  void _showRpePicker(int exerciseIndex, int setIndex, double? initialValue, Workout workout) {
    if (!mounted) return;
    WorkoutInputService.showRpePicker(
      context: context,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      initialValue: initialValue,
      workout: workout,
      onRpeSaved: (exerciseIndex, setIndex, rpe, workout) {
        if (mounted) {
          _saveRpe(exerciseIndex, setIndex, rpe, workout);
        }
      },
    );
  }

  // NOVO: Show weight picker
  void _showWeightPicker(int exerciseIndex, int setIndex, double currentWeight, Workout workout) {
    if (!mounted) return;
    WorkoutInputService.showWeightPicker(
      context: context,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      currentWeight: currentWeight,
      workout: workout,
      onWeightSelected: (exerciseIndex, setIndex, weight, workout) {
        if (mounted) {
          _saveValue('weight', exerciseIndex, setIndex, weight.toString(), workout);
        }
      },
    );
  }

  // NOVO: Show reps picker
  void _showRepsPicker(int exerciseIndex, int setIndex, String? planReps, int currentReps, Workout workout) {
    if (!mounted) return;
    WorkoutInputService.showRepsPicker(
      context: context,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      planReps: planReps,
      currentReps: currentReps,
      workout: workout,
      onRepsSelected: (exerciseIndex, setIndex, reps, workout) {
        if (mounted) {
          _saveValue('reps', exerciseIndex, setIndex, reps.toString(), workout);
        }
      },
    );
  }

  void _saveValue(String field, int exerciseIndex, int setIndex, String value, Workout workout) {
    if (!mounted) return;
    WorkoutStateService.saveValue(
      field: field,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      value: value,
      workout: workout,
      ref: ref,
      scrollController: _scrollController,
      exerciseKeys: _exerciseKeys,
      showNumpad: _showNumpad,
      showWeightPicker: _showWeightPicker,
      showRpePicker: _showRpePicker,
      showRepsPicker: _showRepsPicker,
    );
  }

  void _saveRpe(int exerciseIndex, int setIndex, double rpe, Workout workout) {
    if (!mounted) return; // Proveri da li je widget još uvek mounted
    WorkoutStateService.saveRpe(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      rpe: rpe,
      workout: workout,
      ref: ref,
      scrollController: _scrollController,
      exerciseKeys: _exerciseKeys,
      showNumpad: _showNumpad,
      showWeightPicker: _showWeightPicker,
    );
  }

  void _deleteSet(int exerciseIndex, int setIndex, Workout workout, Key setKey) {
    final deletedSet = WorkoutStateService.deleteSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      workout: workout,
      ref: ref,
      context: context,
    );

    if (deletedSet != null && mounted) {
      _deletedSet = deletedSet;
      _deletedExerciseIndex = exerciseIndex;
      _deletedSetIndex = setIndex;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Set deleted'),
          backgroundColor: AppColors.surface,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.primary,
            onPressed: () {
              _undoDeleteSet(workout);
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _undoDeleteSet(Workout workout) {
    if (_deletedSet == null || _deletedExerciseIndex == null || _deletedSetIndex == null) {
      return;
    }

    WorkoutStateService.undoDeleteSet(
      deletedSet: _deletedSet!,
      exerciseIndex: _deletedExerciseIndex!,
      setIndex: _deletedSetIndex!,
      workout: workout,
      ref: ref,
    );

    _deletedSet = null;
    _deletedExerciseIndex = null;
    _deletedSetIndex = null;
  }

  void _toggleExerciseCompletion(int exerciseIndex, Workout workout) {
    // Set loading state immediately for visual feedback
    setState(() {
      _loadingExercises.add(exerciseIndex);
    });

    WorkoutStateService.toggleExerciseCompletion(
      exerciseIndex: exerciseIndex,
      workout: workout,
      ref: ref,
      context: context,
      workoutStartTime: _workoutStartTime,
      onFastCompletion: (shouldShow) {
        if (shouldShow && !_hasShownFastCompletionMessage && mounted) {
          _hasShownFastCompletionMessage = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mnogo si brzo ovo uradio, nadam se da stvarno jesi 😉'),
                  duration: Duration(seconds: 4),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
          });
        }
      },
    );

    // Remove loading state after UI update (optimistic update happens immediately)
    // Use short delay to allow smooth animation transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _loadingExercises.remove(exerciseIndex);
        });
      }
    });
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex, Workout workout) {
    // Set loading state immediately for visual feedback
    final setKey = '${exerciseIndex}_$setIndex';
    setState(() {
      _loadingSets.add(setKey);
    });

    WorkoutStateService.toggleSetCompletion(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      workout: workout,
      ref: ref,
    );

    // Remove loading state after UI update (optimistic update happens immediately)
    // Use short delay to allow smooth animation transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _loadingSets.remove(setKey);
        });
      }
    });
  }

  Future<void> _finishWorkout(Workout workout) async {
    try {
      await WorkoutStateService.finishWorkout(
        workout: workout,
        ref: ref,
        context: context,
        confettiController: _confettiController!,
      );
    } catch (e) {
      debugPrint('[WorkoutRunner] ❌ ERROR finishing workout: $e');
      // Error dialog is already shown in finishWorkout(), just log here
    }
  }

  // Mark workout as missed (give up)
  Future<void> _markAsMissed(Workout workout) async {
    await WorkoutStateService.markAsMissed(
      workout: workout,
      ref: ref,
      context: context,
    );
  }

  @override
  void dispose() {
    _timerService.dispose();
    _confettiController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to workout changes and manually trigger rebuild only when specific workout changes
    // This prevents rebuild loops while still updating when workout changes
    ref.listen<AsyncValue<List<Workout>>>(workoutControllerProvider, (previous, next) {
      if (mounted && next.hasValue) {
        final workouts = next.value!;
        try {
          final currentWorkout = workouts.firstWhere(
            (w) => w.id == widget.workoutId || w.serverId == widget.workoutId,
          );
          // Only rebuild if workout actually changed (not just reference)
          if (previous?.value != null) {
            final prevWorkouts = previous!.value!;
            try {
              final prevWorkout = prevWorkouts.firstWhere(
                (w) => w.id == widget.workoutId || w.serverId == widget.workoutId,
              );
              // Check if workout actually changed
              if (prevWorkout.isCompleted != currentWorkout.isCompleted ||
                  prevWorkout.isMissed != currentWorkout.isMissed ||
                  prevWorkout.exercises.length != currentWorkout.exercises.length) {
                if (mounted) setState(() {});
              }
            } catch (e) {
              // Previous workout not found, rebuild
              if (mounted) setState(() {});
            }
          }
        } catch (e) {
          // Current workout not found, don't rebuild
        }
      }
    });
    
    // Read workouts state (not watched to prevent rebuild loops)
    final workoutsState = ref.read(workoutControllerProvider);
    final workout = workoutsState.maybeWhen(
      data: (workouts) {
        try {
          return workouts.firstWhere(
            (w) => w.id == widget.workoutId || w.serverId == widget.workoutId,
          );
        } catch (e) {
          return null;
        }
      },
      orElse: () => null,
    );

    // Show loading if checking check-in status
    if (_checkingCheckIn) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(child: ShimmerCard(height: 200)),
        ),
      );
    }

    // Show message if no valid check-in
    if (!_hasValidCheckIn) {
      return const CheckInRequiredWidget();
    }
    
    // REMOVED: Excessive logging causing rebuild loop

    // If workout is null, show loading
    if (workout == null) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(child: ShimmerCard(height: 200)),
        ),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              // REMOVED: Excessive logging in build method causing rebuild loop
              // Logging should be done in initState or specific action handlers, not in build

              // Initialize keys for all exercises if not already done
              for (int i = 0; i < workout.exercises.length; i++) {
                if (!_exerciseKeys.containsKey(i)) {
                  _exerciseKeys[i] = GlobalKey();
                }
              }

              return Column(
                children: [
                  // Header
                  WorkoutHeader(
                    workout: workout,
                    formattedTime: WorkoutTimerService.formatTime(_timerService.elapsedSeconds),
                    isPaused: _timerService.isPaused,
                    onPauseToggle: () {
                      _timerService.togglePause();
                      if (mounted) setState(() {});
                    },
                  ),

                  // Exercise List
                  Expanded(
                    child: workout.exercises.isEmpty
                        ? Center(
                            child: EmptyState(
                              icon: Icons.fitness_center_rounded,
                              title: 'No exercises',
                              message: 'This workout has no exercises yet',
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: workout.exercises.length,
                            itemBuilder: (context, index) {
                              final exercise = workout.exercises[index];
                              // Memoize isExerciseCompleted to prevent recalculation on every rebuild
                              final isExerciseCompleted = exercise.sets.isNotEmpty && 
                                  exercise.sets.every((set) => set.isCompleted);
                              return ExerciseCard(
                                exercise: exercise,
                                exerciseIndex: index,
                                workout: workout,
                                exerciseKey: _exerciseKeys[index]!,
                                isExerciseCompleted: isExerciseCompleted,
                                isLoading: _loadingExercises.contains(index),
                                onToggleCompletion: _toggleExerciseCompletion,
                                onSaveValue: _showNumpad,
                                onWeightSelected: (exerciseIndex, setIndex, weight, workout) {
                                  _showWeightPicker(exerciseIndex, setIndex, weight, workout);
                                },
                                onRepsSelected: (exerciseIndex, setIndex, reps, workout) {
                                  _showRepsPicker(exerciseIndex, setIndex, exercise.planReps, reps, workout);
                                },
                                onSaveRpe: _showRpePicker,
                                onDeleteSet: _deleteSet,
                                onToggleSetCompletion: _toggleSetCompletion,
                                isLoadingSet: (exerciseIndex, setIndex) {
                                  return _loadingSets.contains('${exerciseIndex}_$setIndex');
                                },
                              );
                            },
                          ),
                  ),

                  // Finish Button
                  FinishWorkoutButton(
                    workout: workout,
                    confettiController: _confettiController!,
                    onFinish: () => _finishWorkout(workout),
                    onGiveUp: () => _markAsMissed(workout), // NOVO: Give up callback
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
