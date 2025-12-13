class WorkoutSet {
  final String id;
  final double weight;
  final int reps;
  final double? rpe;
  final bool isCompleted;

  WorkoutSet({required this.id, required this.weight, required this.reps, this.rpe, required this.isCompleted});
}

class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final List<WorkoutSet> sets;
  final String? category; // Chest, Back, Legs, Shoulders, Arms, Core
  final List<String>? equipment; // Bodyweight, Dumbbells, Barbell, Machine, Cable, Kettlebells
  final String? instructions; // Exercise instructions/description
  final int? restSeconds; // Rest time in seconds (from plan)
  final String? notes; // Exercise notes (from plan)
  final int? planSets; // Planned number of sets (from plan)
  final dynamic planReps; // Planned reps - can be int or String like "10-12" (from plan)

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.sets,
    this.category,
    this.equipment,
    this.instructions,
    this.restSeconds,
    this.notes,
    this.planSets,
    this.planReps,
  });
}
