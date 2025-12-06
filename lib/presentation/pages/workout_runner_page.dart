import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/custom_numpad.dart';
import '../../presentation/widgets/rpe_picker.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

class WorkoutRunnerPage extends ConsumerStatefulWidget {
  final String workoutId;
  
  const WorkoutRunnerPage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutRunnerPage> createState() => _WorkoutRunnerPageState();
}

class _WorkoutRunnerPageState extends ConsumerState<WorkoutRunnerPage> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  // Reserved for future inline editing feature
  // ignore: unused_field
  String? _editingField; // 'weight', 'reps', 'rpe'
  String _editingValue = '';
  // ignore: unused_field
  int? _editingExerciseIndex;
  // ignore: unused_field
  int? _editingSetIndex;
  WorkoutSet? _deletedSet;
  int? _deletedExerciseIndex;
  int? _deletedSetIndex;
  ConfettiController? _confettiController;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _exerciseKeys = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    AppHaptic.medium();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showNumpad(String field, int exerciseIndex, int setIndex, String initialValue, [workout]) {
    setState(() {
      _editingField = field;
      _editingExerciseIndex = exerciseIndex;
      _editingSetIndex = setIndex;
      _editingValue = initialValue;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomNumpad(
        initialValue: initialValue,
        allowDecimal: field == 'weight',
        onValueChanged: (value) {
          setState(() {
            _editingValue = value;
          });
        },
        onConfirm: () {
          if (workout != null) {
            _saveValue(field, exerciseIndex, setIndex, _editingValue, workout);
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      setState(() {
        _editingField = null;
        _editingValue = '';
      });
    });
  }

  void _showRpePicker(int exerciseIndex, int setIndex, double? initialValue, [workout]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RpePicker(
        initialValue: initialValue,
        onRpeSelected: (rpe) {
          Navigator.pop(context);
          if (workout != null) {
            _saveRpe(exerciseIndex, setIndex, rpe, workout);
          }
        },
      ),
    );
  }

  void _saveValue(String field, int exerciseIndex, int setIndex, String value, workout) {
    AppHaptic.medium();
    
    // Parse value
    final numValue = field == 'weight' 
        ? double.tryParse(value) ?? 0.0
        : int.tryParse(value) ?? 0;
    
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
    );
    
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;
    
    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );
    
    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
    
    // Auto-advance: weight -> reps -> RPE -> next set
    if (field == 'weight') {
      // After weight, open reps
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showNumpad('reps', exerciseIndex, setIndex, set.reps.toString(), updatedWorkout);
        }
      });
    } else if (field == 'reps') {
      // After reps, open RPE
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showRpePicker(exerciseIndex, setIndex, set.rpe, updatedWorkout);
        }
      });
    }
  }

  void _saveRpe(int exerciseIndex, int setIndex, double rpe, workout) {
    AppHaptic.medium();
    
    // Update workout set
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    
    final updatedSet = WorkoutSet(
      id: set.id,
      weight: set.weight,
      reps: set.reps,
      rpe: rpe,
      isCompleted: set.isCompleted,
    );
    
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = updatedSet;
    
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
    );
    
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;
    
    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );
    
    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
    
    // Auto-advance: After RPE, move to next set
    final nextSetIndex = setIndex + 1;
    if (nextSetIndex < exercise.sets.length) {
      // Move to next set in same exercise
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final nextSet = exercise.sets[nextSetIndex];
          _showNumpad('weight', exerciseIndex, nextSetIndex, nextSet.weight.toString(), updatedWorkout);
        }
      });
    } else {
      // Move to next exercise
      final nextExerciseIndex = exerciseIndex + 1;
      if (nextExerciseIndex < workout.exercises.length) {
        final nextExercise = workout.exercises[nextExerciseIndex];
        if (nextExercise.sets.isNotEmpty) {
          // Scroll to next exercise before opening numpad
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _scrollController.hasClients) {
              final key = _exerciseKeys[nextExerciseIndex];
              if (key != null && key.currentContext != null) {
                Scrollable.ensureVisible(
                  key.currentContext!,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: 0.1, // Slight offset from top
                );
              }
            }
          });
          
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) {
              final nextSet = nextExercise.sets[0];
              _showNumpad('weight', nextExerciseIndex, 0, nextSet.weight.toString(), updatedWorkout);
            }
          });
        }
      }
    }
  }
  
  void _deleteSet(int exerciseIndex, int setIndex, workout, Key setKey) {
    AppHaptic.medium();
    
    // Store deleted set for undo
    final exercise = workout.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    _deletedSet = set;
    _deletedExerciseIndex = exerciseIndex;
    _deletedSetIndex = setIndex;
    
    // Remove set from exercise
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: List.from(exercise.sets)..removeAt(setIndex),
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
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );
    
    // Save to repository
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
    
    // Show undo snackbar
    if (mounted) {
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
    if (_deletedSet == null || 
        _deletedExerciseIndex == null || 
        _deletedSetIndex == null) {
      return;
    }
    
    AppHaptic.light();
    
    final exercise = workout.exercises[_deletedExerciseIndex!];
    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets.insert(_deletedSetIndex!, _deletedSet!);
    
    final updatedExercise = Exercise(
      id: exercise.id,
      name: exercise.name,
      targetMuscle: exercise.targetMuscle,
      sets: updatedSets,
    );
    
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[_deletedExerciseIndex!] = updatedExercise;
    
    final updatedWorkout = Workout(
      id: workout.id,
      serverId: workout.serverId,
      name: workout.name,
      scheduledDate: workout.scheduledDate,
      isCompleted: workout.isCompleted,
      exercises: updatedExercises,
      isDirty: true,
      updatedAt: DateTime.now(),
    );
    
    ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
    
    // Clear deleted set info
    _deletedSet = null;
    _deletedExerciseIndex = null;
    _deletedSetIndex = null;
  }

  Future<void> _finishWorkout(Workout workout) async {
    AppHaptic.heavy();
    
    try {
      // Mark workout as completed
      final updatedWorkout = Workout(
        id: workout.id,
        serverId: workout.serverId,
        name: workout.name,
        scheduledDate: workout.scheduledDate,
        isCompleted: true,
        exercises: workout.exercises,
        isDirty: true,
        updatedAt: DateTime.now(),
      );
      
      // Save to repository
      await ref.read(workoutControllerProvider.notifier).updateWorkout(updatedWorkout);
      
      // Show confetti animation
      _confettiController?.play();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout completed! Great job!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Navigate back after animation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/home');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finishing workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutControllerProvider);
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return Center(
                  child: Text(
                    'No workouts available',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }
              
              final workout = workouts.firstWhere(
                (w) => w.id == widget.workoutId,
                orElse: () => workouts.first,
              );
              
              return Column(
                children: [
                  // Header
                  _buildHeader(context, workout),
                  
                  // Exercise List
                  Expanded(
                    child: _buildExerciseList(context, workout),
                  ),
                  
                  // Finish Button
                  _buildFinishButton(context, workout),
                ],
              );
            },
                  loading: () => const Center(
                    child: ShimmerCard(height: 200),
                  ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, workout) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  workout.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _togglePause,
                icon: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timer
          GradientCard(
            gradient: AppGradients.primary,
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, workout) {
    if (workout.exercises.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'No exercises',
          message: 'This workout has no exercises yet',
        ),
      );
    }
    
    // Initialize keys for all exercises if not already done
    for (int i = 0; i < workout.exercises.length; i++) {
      if (!_exerciseKeys.containsKey(i)) {
        _exerciseKeys[i] = GlobalKey();
      }
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: workout.exercises.length,
      itemBuilder: (context, index) {
        final exercise = workout.exercises[index];
        return _buildExerciseCard(context, exercise, index, workout);
      },
    );
  }

  Widget _buildExerciseCard(BuildContext context, exercise, int exerciseIndex, workout) {
    return GradientCard(
      key: _exerciseKeys[exerciseIndex],
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Name
          Text(
            exercise.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            exercise.targetMuscle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          
          // Sets
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            
            return _buildSetRow(context, set, exerciseIndex, setIndex, workout);
          }),
          
          // Add Set Button
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // TODO: Add new set
              AppHaptic.selection();
            },
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
            ),
            label: Text(
              'Add Set',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, set, int exerciseIndex, int setIndex, workout) {
    final setKey = Key('set_${exerciseIndex}_$setIndex');
    
    return Dismissible(
      key: setKey,
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.textPrimary,
          size: 32,
        ),
      ),
      onDismissed: (direction) {
        _deleteSet(exerciseIndex, setIndex, workout, setKey);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: set.isCompleted
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: set.isCompleted
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.3),
            width: set.isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Set Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: set.isCompleted
                    ? AppGradients.success
                    : AppGradients.card,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${setIndex + 1}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Weight
            Expanded(
              child: _buildInputField(
                context,
                '${set.weight} kg',
                () => _showNumpad('weight', exerciseIndex, setIndex, set.weight.toString(), workout),
              ),
            ),
            const SizedBox(width: 8),
            
            // Reps
            Expanded(
              child: _buildInputField(
                context,
                '${set.reps} reps',
                () => _showNumpad('reps', exerciseIndex, setIndex, set.reps.toString(), workout),
              ),
            ),
            const SizedBox(width: 8),
            
            // RPE
            Expanded(
              child: _buildInputField(
                context,
                set.rpe != null ? 'RPE ${set.rpe}' : 'RPE',
                () => _showRpePicker(exerciseIndex, setIndex, set.rpe, workout),
              ),
            ),
            const SizedBox(width: 8),
            
            // Complete Checkbox
            GestureDetector(
              onTap: () {
                AppHaptic.selection();
                // TODO: Toggle set completion
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: set.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: set.isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: set.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppGradients.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFinishButton(BuildContext context, Workout workout) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background,
              ],
            ),
          ),
          child: NeonButton(
            text: 'Finish Workout',
            icon: Icons.check_circle_rounded,
            onPressed: () => _finishWorkout(workout),
            gradient: AppGradients.success,
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController!,
            blastDirection: 3.14 / 2, // Down
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}
