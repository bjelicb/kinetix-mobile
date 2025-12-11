import 'package:flutter/material.dart';
import '../../../domain/entities/exercise.dart';
import 'exercise_item_widget.dart';
import 'exercise_empty_state_widget.dart';

/// Widget for displaying the list of exercises
class ExerciseListWidget extends StatelessWidget {
  final List<Exercise> exercises;
  final Set<String> selectedExerciseIds;
  final Function(Exercise) onExerciseTap;
  final Function(Exercise) onToggleSelection;
  final Function(Exercise) onShowDetails;

  const ExerciseListWidget({
    super.key,
    required this.exercises,
    required this.selectedExerciseIds,
    required this.onExerciseTap,
    required this.onToggleSelection,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const ExerciseEmptyStateWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = selectedExerciseIds.contains(exercise.id);
        return ExerciseItemWidget(
          exercise: exercise,
          isSelected: isSelected,
          onTap: onExerciseTap,
          onToggleSelection: onToggleSelection,
          onShowDetails: onShowDetails,
        );
      },
    );
  }
}

