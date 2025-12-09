import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_mobile/data/repositories/plan_repository_impl.dart';
import 'package:kinetix_mobile/data/datasources/local_data_source.dart';

void main() {
  group('PlanRepository Tests', () {
    late PlanRepositoryImpl repository;
    late LocalDataSource localDataSource;

    setUp(() {
      localDataSource = LocalDataSource();
      repository = PlanRepositoryImpl(localDataSource, null);
    });

    test('getCurrentPlan returns null when no plans exist', () async {
      // Act
      final result = await repository.getCurrentPlan('user123');

      // Assert
      expect(result, null);
    });

    test('getPlanById returns null when plan not found', () async {
      // Act
      final result = await repository.getPlanById('nonexistent');

      // Assert
      expect(result, null);
    });

    test('getAllPlans returns empty list when no plans exist', () async {
      // Act
      final result = await repository.getAllPlans('user123', 'CLIENT');

      // Assert
      expect(result, isEmpty);
    });

    test('getPlansByTrainer returns empty list when no plans exist', () async {
      // Act
      final result = await repository.getPlansByTrainer('trainer123');

      // Assert
      expect(result, isEmpty);
    });
  });
}

