import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/exercise.dart';
import '../gradient_card.dart';
import 'exercise_card_widget.dart';
import 'exercise_list_empty_state_widget.dart';

/// Exercise list widget for workout edit
class ExerciseListWidget extends StatelessWidget {
  final List<Exercise> exercises;
  final VoidCallback onAddExercise;
  final Function(int) onRemoveExercise;

  const ExerciseListWidget({
    super.key,
    required this.exercises,
    required this.onAddExercise,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: onAddExercise,
                icon: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                ),
                label: const Text('Add Exercise'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (exercises.isEmpty)
            const ExerciseListEmptyState()
          else
            ...exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return ExerciseCardWidget(
                exercise: exercise,
                onDelete: () => onRemoveExercise(index),
              );
            }),
        ],
      ),
    );
  }
}

