import 'package:flutter/material.dart';
import '../widgets/plan_preview_dialog.dart';
import '../plan_builder/models/plan_builder_models.dart';

/// Service for showing plan preview dialog
class PlanPreviewService {
  /// Show plan preview dialog
  static void showPlanPreview({
    required BuildContext context,
    required String planName,
    required String difficulty,
    required String description,
    required List<WorkoutDayData> workoutDays,
  }) {
    showDialog(
      context: context,
      builder: (_) => PlanPreviewDialog(
        planName: planName,
        difficulty: difficulty,
        description: description,
        workoutDays: workoutDays,
      ),
    );
  }
}

