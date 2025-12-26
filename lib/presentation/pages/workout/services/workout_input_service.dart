import 'package:flutter/material.dart';
import '../../../../domain/entities/workout.dart';
import '../../../../presentation/widgets/custom_numpad.dart';
import '../../../../presentation/widgets/rpe_picker.dart';
import '../../../../presentation/widgets/reps_picker.dart';
import '../../../../presentation/widgets/weight_picker.dart';

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

  /// Show weight picker modal
  static void showWeightPicker({
    required BuildContext context,
    required int exerciseIndex,
    required int setIndex,
    required double currentWeight,
    required Workout workout,
    required Function(int, int, double, Workout) onWeightSelected,
  }) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[WorkoutInputService:WeightPicker] 🚀 SHOW WEIGHT PICKER CALLED');
    debugPrint('[WorkoutInputService:WeightPicker] exerciseIndex: $exerciseIndex');
    debugPrint('[WorkoutInputService:WeightPicker] setIndex: $setIndex');
    debugPrint('[WorkoutInputService:WeightPicker] currentWeight: $currentWeight');
    debugPrint('[WorkoutInputService:WeightPicker] workout.id: ${workout.id}');
    debugPrint('[WorkoutInputService:WeightPicker] About to show modal bottom sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Ne dozvoljava zatvaranje klikom van modala - mora Confirm
      enableDrag: false, // Ne dozvoljava drag da zatvori modal
      builder: (context) {
        debugPrint('[WorkoutInputService:WeightPicker] Builder called, creating WeightPicker widget');
        return PopScope(
          canPop: false, // Ne dozvoljava zatvaranje back button-om
          onPopInvokedWithResult: (didPop, result) {
            debugPrint('[WorkoutInputService:WeightPicker] PopScope onPopInvokedWithResult called - didPop: $didPop');
            if (didPop) {
              debugPrint('[WorkoutInputService:WeightPicker] ⚠️ PopScope was popped! This should not happen.');
            }
          },
          child: WeightPicker(
            initialValue: currentWeight,
            onWeightSelected: (weight) {
              debugPrint('═══════════════════════════════════════════════════════════');
              debugPrint('[WorkoutInputService:WeightPicker] 📞 CALLBACK onWeightSelected CALLED');
              debugPrint('[WorkoutInputService:WeightPicker] weight: $weight');
              debugPrint('[WorkoutInputService:WeightPicker] exerciseIndex: $exerciseIndex');
              debugPrint('[WorkoutInputService:WeightPicker] setIndex: $setIndex');
              debugPrint('[WorkoutInputService:WeightPicker] About to call onWeightSelected callback');
              // Navigator.pop se poziva u WeightPicker Confirm dugmetu
              onWeightSelected(exerciseIndex, setIndex, weight, workout);
              debugPrint('[WorkoutInputService:WeightPicker] ✅ Callback onWeightSelected completed');
              debugPrint('═══════════════════════════════════════════════════════════');
            },
          ),
        );
      },
    );
    debugPrint('[WorkoutInputService:WeightPicker] ✅ showModalBottomSheet called');
    debugPrint('═══════════════════════════════════════════════════════════');
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
      isDismissible: false, // Ne dozvoljava zatvaranje klikom van modala - mora Confirm
      enableDrag: false, // Ne dozvoljava drag da zatvori modal
      builder: (context) => PopScope(
        canPop: false, // NOVO: Ne dozvoljava zatvaranje back button-om
        child: RpePicker(
          initialValue: initialValue,
          onRpeSelected: (rpe) {
            // Navigator.pop se poziva u RpePicker Confirm dugmetu
            onRpeSaved(exerciseIndex, setIndex, rpe, workout);
          },
        ),
      ),
    );
  }

  /// Show reps picker modal with options from planReps
  static void showRepsPicker({
    required BuildContext context,
    required int exerciseIndex,
    required int setIndex,
    required String? planReps,
    required int currentReps,
    required Workout workout,
    required Function(int, int, int, Workout) onRepsSelected,
  }) {
    // Parse planReps to extract reps options
    List<int> repsOptions = [10]; // Default fallback

    if (planReps != null && planReps.isNotEmpty) {
      // Try to parse different formats: "10", "8-12", "5x5", "10, 8, 6"

      // Format 1: Single number "10" - generiši opcije od 1 do maksimuma
      final singleNumber = int.tryParse(planReps.trim());
      if (singleNumber != null) {
        // Generiši opcije od 1 do maksimuma
        repsOptions = List.generate(singleNumber, (i) => i + 1);
      }
      // Format 2: Range "8-12"
      else if (planReps.contains('-')) {
        final rangeMatch = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(planReps);
        if (rangeMatch != null) {
          final start = int.tryParse(rangeMatch.group(1) ?? '10') ?? 10;
          final end = rangeMatch.group(2) != null ? int.tryParse(rangeMatch.group(2)!) : null;
          if (end != null && end > start) {
            repsOptions = List.generate(end - start + 1, (i) => start + i);
          } else {
            repsOptions = [start];
          }
        }
      }
      // Format 3: Comma-separated "10, 8, 6"
      else if (planReps.contains(',')) {
        repsOptions = planReps.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
        if (repsOptions.isEmpty) {
          repsOptions = [10]; // Fallback
        }
      }
      // Format 4: "5x5" - extract first number
      else if (planReps.contains('x')) {
        final firstNumber = int.tryParse(planReps.split('x').first.trim());
        if (firstNumber != null) {
          repsOptions = [firstNumber];
        }
      }
    }

    // Prikazati bottom sheet sa picker-om
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Ne dozvoljava zatvaranje klikom van modala - mora Confirm
      enableDrag: false, // Ne dozvoljava drag da zatvori modal
      builder: (context) {
        debugPrint('[WorkoutInputService:RepsPicker] Builder called, creating RepsPicker widget');
        return PopScope(
          canPop: false, // NOVO: Ne dozvoljava zatvaranje back button-om
          onPopInvokedWithResult: (didPop, result) {
            debugPrint('[WorkoutInputService:RepsPicker] PopScope onPopInvokedWithResult called - didPop: $didPop');
            if (didPop) {
              debugPrint('[WorkoutInputService:RepsPicker] ⚠️ PopScope was popped! This should not happen.');
            }
          },
          child: RepsPicker(
            options: repsOptions,
            initialValue: currentReps,
            onRepsSelected: (reps) {
              debugPrint('═══════════════════════════════════════════════════════════');
              debugPrint('[WorkoutInputService:RepsPicker] 📞 CALLBACK onRepsSelected CALLED');
              debugPrint('[WorkoutInputService:RepsPicker] reps: $reps');
              debugPrint('[WorkoutInputService:RepsPicker] exerciseIndex: $exerciseIndex');
              debugPrint('[WorkoutInputService:RepsPicker] setIndex: $setIndex');
              debugPrint('[WorkoutInputService:RepsPicker] About to call onRepsSelected callback');
              // Navigator.pop se već poziva u RepsPicker._onConfirm(), ne treba ovde
              onRepsSelected(exerciseIndex, setIndex, reps, workout);
              debugPrint('[WorkoutInputService:RepsPicker] ✅ Callback onRepsSelected completed');
              debugPrint('═══════════════════════════════════════════════════════════');
            },
          ),
        );
      },
    );
  }
}
