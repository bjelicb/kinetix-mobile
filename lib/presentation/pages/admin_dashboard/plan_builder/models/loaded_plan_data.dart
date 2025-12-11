import '../models/plan_builder_models.dart';

/// Data class for loaded plan initialization
class LoadedPlanData {
  final String name;
  final String description;
  final String difficulty;
  final String? weeklyCost;
  final String? selectedTrainerId;
  final List<WorkoutDayData> workoutDays;
  final bool isPlanEditable;

  LoadedPlanData({
    required this.name,
    required this.description,
    required this.difficulty,
    this.weeklyCost,
    this.selectedTrainerId,
    required this.workoutDays,
    required this.isPlanEditable,
  });
}

