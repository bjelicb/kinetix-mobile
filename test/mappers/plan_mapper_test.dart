import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_mobile/data/mappers/plan_mapper.dart';
import 'package:kinetix_mobile/domain/entities/plan.dart';

void main() {
  group('PlanMapper Tests', () {
    test('toEntity converts DTO to Plan entity correctly', () {
      // Arrange
      final dto = {
        '_id': 'plan123',
        'name': 'Test Plan',
        'difficulty': 'INTERMEDIATE',
        'description': 'Test description',
        'trainerId': 'trainer123',
        'workouts': [
          {
            'dayOfWeek': 1,
            'isRestDay': false,
            'name': 'Push Day',
            'exercises': [
              {
                'name': 'Bench Press',
                'sets': 4,
                'reps': '8-10',
                'restSeconds': 90,
                'notes': 'Focus on form',
                'videoUrl': 'https://example.com/video.mp4',
                'targetMuscle': 'Chest',
              }
            ],
            'estimatedDuration': 60,
            'notes': 'Warm up first',
          }
        ],
      };

      // Act
      final entity = PlanMapper.toEntity(dto);

      // Assert
      expect(entity.id, 'plan123');
      expect(entity.name, 'Test Plan');
      expect(entity.difficulty, 'INTERMEDIATE');
      expect(entity.description, 'Test description');
      expect(entity.trainerId, 'trainer123');
      expect(entity.workoutDays.length, 1);
      expect(entity.workoutDays[0].dayOfWeek, 1);
      expect(entity.workoutDays[0].name, 'Push Day');
      expect(entity.workoutDays[0].exercises.length, 1);
      expect(entity.workoutDays[0].exercises[0].name, 'Bench Press');
      expect(entity.workoutDays[0].exercises[0].sets, 4);
      expect(entity.workoutDays[0].exercises[0].reps, '8-10');
    });

    test('toCollection converts entity to Collection correctly', () {
      // Arrange
      final entity = Plan(
        id: 'plan123',
        name: 'Test Plan',
        difficulty: 'INTERMEDIATE',
        description: 'Test description',
        trainerId: 'trainer123',
        workoutDays: [
          WorkoutDay(
            dayOfWeek: 1,
            isRestDay: false,
            name: 'Push Day',
            exercises: [
              PlanExercise(
                name: 'Bench Press',
                sets: 4,
                reps: '8-10',
                restSeconds: 90,
                notes: 'Focus on form',
                videoUrl: 'https://example.com/video.mp4',
                targetMuscle: 'Chest',
              ),
            ],
            estimatedDuration: 60,
            notes: 'Warm up first',
          ),
        ],
      );

      // Act
      final collection = PlanMapper.toCollection(entity);

      // Assert
      expect(collection.planId, 'plan123');
      expect(collection.name, 'Test Plan');
      expect(collection.difficulty, 'INTERMEDIATE');
      expect(collection.description, 'Test description');
      expect(collection.trainerId, 'trainer123');
      expect(collection.workoutDays.length, 1);
      expect(collection.isDirty, false);
    });

    test('toDto converts entity to DTO correctly', () {
      // Arrange
      final entity = Plan(
        id: 'plan123',
        name: 'Test Plan',
        difficulty: 'INTERMEDIATE',
        trainerId: 'trainer123',
        workoutDays: [
          WorkoutDay(
            dayOfWeek: 1,
            isRestDay: false,
            name: 'Push Day',
            exercises: [],
            estimatedDuration: 60,
          ),
        ],
      );

      // Act
      final dto = PlanMapper.toDto(entity);

      // Assert
      expect(dto['_id'], 'plan123');
      expect(dto['name'], 'Test Plan');
      expect(dto['difficulty'], 'INTERMEDIATE');
      expect(dto['trainerId'], 'trainer123');
      expect(dto['workouts'], isA<List>());
      expect((dto['workouts'] as List).length, 1);
    });

    test('handles null values correctly', () {
      // Arrange
      final dto = {
        '_id': 'plan123',
        'name': 'Test Plan',
        'difficulty': 'INTERMEDIATE',
        'trainerId': 'trainer123',
        'workouts': [],
      };

      // Act
      final entity = PlanMapper.toEntity(dto);

      // Assert
      expect(entity.description, null);
      expect(entity.workoutDays.length, 0);
    });
  });
}

