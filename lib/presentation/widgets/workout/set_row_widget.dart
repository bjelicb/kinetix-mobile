import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/workout.dart';
import 'workout_input_field_widget.dart';

class SetRow extends StatelessWidget {
  final WorkoutSet set;
  final int exerciseIndex;
  final int setIndex;
  final Workout workout;
  final Key setKey;
  final bool isLoading;
  final Function(String, int, int, String, Workout) onSaveValue;
  final Function(int, int, double, Workout)? onWeightSelected; // NOVO - optional callback za weight picker
  final Function(int, int, int, Workout)? onRepsSelected; // NOVO - optional callback za reps picker
  final Function(int, int, double?, Workout) onSaveRpe;
  final Function(int, int, Workout, Key) onDeleteSet;
  final Function(int, int, Workout) onToggleSetCompletion;

  const SetRow({
    super.key,
    required this.set,
    required this.exerciseIndex,
    required this.setIndex,
    required this.workout,
    required this.setKey,
    this.isLoading = false,
    required this.onSaveValue,
    this.onWeightSelected, // NOVO - optional
    this.onRepsSelected, // NOVO - optional
    required this.onSaveRpe,
    required this.onDeleteSet,
    required this.onToggleSetCompletion,
  });

  @override
  Widget build(BuildContext context) {
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
        onDeleteSet(exerciseIndex, setIndex, workout, setKey);
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Weight - NOVO: Koristiti onWeightSelected ako postoji, inače onSaveValue
            Expanded(
              child: WorkoutInputField(
                label: '${set.weight} kg',
                onTap: () {
                  if (onWeightSelected != null) {
                    // Koristiti weight picker
                    onWeightSelected!(exerciseIndex, setIndex, set.weight, workout);
                  } else {
                    // Fallback na numpad
                    onSaveValue('weight', exerciseIndex, setIndex, set.weight.toString(), workout);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            
            // Reps - NOVO: Koristiti onRepsSelected ako postoji, inače onSaveValue
            Expanded(
              child: WorkoutInputField(
                label: '${set.reps} reps',
                onTap: () {
                  if (onRepsSelected != null) {
                    // Koristiti reps picker
                    onRepsSelected!(exerciseIndex, setIndex, set.reps, workout);
                  } else {
                    // Fallback na numpad
                    onSaveValue('reps', exerciseIndex, setIndex, set.reps.toString(), workout);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            
            // RPE
            Expanded(
              child: WorkoutInputField(
                label: set.rpe != null ? 'RPE ${set.rpe}' : 'RPE',
                onTap: () => onSaveRpe(exerciseIndex, setIndex, set.rpe, workout),
              ),
            ),
            const SizedBox(width: 8),
            
            // Complete Checkbox
            GestureDetector(
              onTap: () {
                if (!isLoading) {
                  onToggleSetCompletion(exerciseIndex, setIndex, workout);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: set.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: set.isCompleted
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
                    : (set.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
                          )
                        : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

