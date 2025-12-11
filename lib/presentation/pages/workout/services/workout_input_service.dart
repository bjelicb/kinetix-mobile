import 'package:flutter/material.dart';
import '../../../../domain/entities/workout.dart';
import '../../../../presentation/widgets/custom_numpad.dart';
import '../../../../presentation/widgets/rpe_picker.dart';

/// Service for handling workout input (numpad, RPE picker)
class WorkoutInputService {
  /// Show numpad modal for weight/reps input
  static void showNumpad({
    required BuildContext context,
    required String field,
    required int exerciseIndex,
    required int setIndex,
    required String initialValue,
    required Workout workout,
    required Function(String, int, int, String, Workout) onValueSaved,
  }) {
    String editingValue = initialValue;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CustomNumpad(
          initialValue: initialValue,
          allowDecimal: field == 'weight',
          onValueChanged: (value) {
            setModalState(() {
              editingValue = value;
            });
          },
          onConfirm: () {
            onValueSaved(field, exerciseIndex, setIndex, editingValue, workout);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Show RPE picker modal
  static void showRpePicker({
    required BuildContext context,
    required int exerciseIndex,
    required int setIndex,
    required double? initialValue,
    required Workout workout,
    required Function(int, int, double, Workout) onRpeSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RpePicker(
        initialValue: initialValue,
        onRpeSelected: (rpe) {
          Navigator.pop(context);
          onRpeSaved(exerciseIndex, setIndex, rpe, workout);
        },
      ),
    );
  }
}

