class Plan {
  final String id; // Server ID
  final String name;
  final String difficulty;
  final String? description;
  final String trainerId;
  final String? trainerName; // Trainer's name for display
  final double? weeklyCost; // Weekly cost in euros
  final List<WorkoutDay> workoutDays;
  
  Plan({
    required this.id,
    required this.name,
    required this.difficulty,
    this.description,
    required this.trainerId,
    this.trainerName,
    this.weeklyCost,
    required this.workoutDays,
  });
}

class WorkoutDay {
  final int dayOfWeek; // 1-7 (Monday-Sunday)
  final bool isRestDay;
  final String name;
  final List<PlanExercise> exercises;
  final int estimatedDuration; // minutes
  final String? notes;
  
  WorkoutDay({
    required this.dayOfWeek,
    required this.isRestDay,
    required this.name,
    required this.exercises,
    required this.estimatedDuration,
    this.notes,
  });
  
  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Day $dayOfWeek';
    }
  }
}

class PlanExercise {
  final String name;
  final int sets;
  final String reps; // Can be "10-12" or number string
  final int restSeconds;
  final String? notes;
  final String? videoUrl;
  final String? targetMuscle;
  
  PlanExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
    this.videoUrl,
    this.targetMuscle,
  });
  
  String get formattedRest {
    if (restSeconds < 60) {
      return '${restSeconds}s';
    }
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    if (seconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}

