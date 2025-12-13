import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  WorkoutSet? _deletedSet;
  int? _deletedExerciseIndex;
  int? _deletedSetIndex;

  @override
  void initState() {
    super.initState();
    _timerService = WorkoutTimerService();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _workoutStartTime = DateTime.now();
    debugPrint('[WorkoutRunner:Init] Workout started at $_workoutStartTime');
    _timerService.startTimer(() {
      if (mounted) setState(() {});
    });
    _checkCheckInStatus();
  }

  Future<void> _checkCheckInStatus() async {
    final result = await WorkoutValidationService.checkCheckInStatus();

    if (!mounted) return;

    setState(() {
      _hasValidCheckIn = result.hasValidCheckIn;
      _checkingCheckIn = false;
    });

    if (!_hasValidCheckIn && mounted) {
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
    WorkoutInputService.showRpePicker(
      context: context,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      initialValue: initialValue,
      workout: workout,
      onRpeSaved: (exerciseIndex, setIndex, rpe, workout) {
        _saveRpe(exerciseIndex, setIndex, rpe, workout);
      },
    );
  }

  void _saveValue(String field, int exerciseIndex, int setIndex, String value, Workout workout) {
    WorkoutStateService.saveValue(
      field: field,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      value: value,
      workout: workout,
      ref: ref,
      context: context,
      scrollController: _scrollController,
      exerciseKeys: _exerciseKeys,
      showNumpad: _showNumpad,
      showRpePicker: _showRpePicker,
    );
  }

  void _saveRpe(int exerciseIndex, int setIndex, double rpe, Workout workout) {
    WorkoutStateService.saveRpe(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      rpe: rpe,
      workout: workout,
      ref: ref,
      context: context,
      scrollController: _scrollController,
      exerciseKeys: _exerciseKeys,
      showNumpad: _showNumpad,
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
  }

  Future<void> _finishWorkout(Workout workout) async {
    await WorkoutStateService.finishWorkout(
      workout: workout,
      ref: ref,
      context: context,
      confettiController: _confettiController!,
    );

    // Navigate back after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/home');
      }
    });
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
    final workoutsState = ref.watch(workoutControllerProvider);

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

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return Center(child: Text('No workouts available', style: Theme.of(context).textTheme.bodyLarge));
              }

              final workout = workouts.firstWhere((w) => w.id == widget.workoutId, orElse: () => workouts.first);

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
                              return ExerciseCard(
                                exercise: exercise,
                                exerciseIndex: index,
                                workout: workout,
                                exerciseKey: _exerciseKeys[index]!,
                                isExerciseCompleted: WorkoutStateService.isExerciseCompleted(exercise),
                                onToggleCompletion: _toggleExerciseCompletion,
                                onSaveValue: _showNumpad,
                                onSaveRpe: _showRpePicker,
                                onDeleteSet: _deleteSet,
                              );
                            },
                          ),
                  ),

                  // Finish Button
                  FinishWorkoutButton(
                    workout: workout,
                    confettiController: _confettiController!,
                    onFinish: () => _finishWorkout(workout),
                  ),
                ],
              );
            },
            loading: () => const Center(child: ShimmerCard(height: 200)),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}
