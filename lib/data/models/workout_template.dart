class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final List<TemplateExercise> exercises;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class TemplateExercise {
  final String exerciseId;
  final String name;
  final int defaultSets;
  final double? defaultWeight;
  final int? defaultReps;

  TemplateExercise({
    required this.exerciseId,
    required this.name,
    required this.defaultSets,
    this.defaultWeight,
    this.defaultReps,
  });

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      defaultSets: json['defaultSets'] as int,
      defaultWeight: json['defaultWeight'] != null
          ? (json['defaultWeight'] as num).toDouble()
          : null,
      defaultReps: json['defaultReps'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'defaultSets': defaultSets,
      if (defaultWeight != null) 'defaultWeight': defaultWeight,
      if (defaultReps != null) 'defaultReps': defaultReps,
    };
  }
}
