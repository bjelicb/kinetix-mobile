import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/workout.dart';
import '../gradient_card.dart';
import 'set_row_widget.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final Workout workout;
  final GlobalKey exerciseKey;
  final bool isExerciseCompleted;
  final bool isLoading;
  final Function(int, Workout) onToggleCompletion;
  final Function(String, int, int, String, Workout) onSaveValue;
  final Function(int, int, double, Workout)? onWeightSelected; // NOVO - optional callback za weight picker
  final Function(int, int, int, Workout)? onRepsSelected; // NOVO - optional callback za reps picker
  final Function(int, int, double?, Workout) onSaveRpe;
  final Function(int, int, Workout, Key) onDeleteSet;
  final Function(int, int, Workout) onToggleSetCompletion;
  final Function(int, int)? isLoadingSet; // Returns true if set is loading

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.workout,
    required this.exerciseKey,
    required this.isExerciseCompleted,
    this.isLoading = false,
    required this.onToggleCompletion,
    required this.onSaveValue,
    this.onWeightSelected, // NOVO - optional
    this.onRepsSelected, // NOVO - optional
    required this.onSaveRpe,
    required this.onDeleteSet,
    required this.onToggleSetCompletion,
    this.isLoadingSet, // NOVO - optional callback to check if set is loading
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      key: exerciseKey,
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header with Checkbox
          Row(
            children: [
              // Exercise Checkbox (PREČICA - toggles ALL sets)
              GestureDetector(
                onTap: () {
                  if (!isLoading) {
                    onToggleCompletion(exerciseIndex, workout);
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExerciseCompleted
                        ? AppColors.success
                        : Colors.transparent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isExerciseCompleted
                          ? AppColors.success
                          : AppColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                              ),
                            ),
                          ),
                        )
                      : (isExerciseCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            )
                          : null),
                ),
              ),
              const SizedBox(width: 12),
              // Exercise Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (exercise.targetMuscle.isNotEmpty && exercise.targetMuscle != 'Unknown') ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.targetMuscle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sets
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            final setKey = Key('set_${exerciseIndex}_$setIndex');
            
            return SetRow(
              set: set,
              exerciseIndex: exerciseIndex,
              setIndex: setIndex,
              workout: workout,
              setKey: setKey,
              isLoading: isLoadingSet != null ? isLoadingSet!(exerciseIndex, setIndex) : false,
              onSaveValue: onSaveValue,
              onWeightSelected: onWeightSelected != null
                  ? (exerciseIndex, setIndex, weight, workout) {
                      onWeightSelected!(exerciseIndex, setIndex, weight, workout);
                    }
                  : null,
              onRepsSelected: onRepsSelected != null
                  ? (exerciseIndex, setIndex, reps, workout) {
                      onRepsSelected!(exerciseIndex, setIndex, reps, workout);
                    }
                  : null,
              onSaveRpe: onSaveRpe,
              onDeleteSet: onDeleteSet,
              onToggleSetCompletion: onToggleSetCompletion,
            );
          }),
        ],
      ),
    );
  }
}

