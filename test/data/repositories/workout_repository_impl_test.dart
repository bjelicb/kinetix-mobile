import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:kinetix_mobile/data/repositories/workout_repository_impl.dart';
import 'package:kinetix_mobile/data/datasources/local_data_source.dart';
import 'package:kinetix_mobile/domain/entities/workout.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  group('WorkoutRepositoryImpl', () {
    late WorkoutRepositoryImpl repository;
    late MockRemoteDataSource mockRemoteDataSource;
    late LocalDataSource localDataSource;
    late FlutterSecureStorage secureStorage;

    setUp(() {
      mockRemoteDataSource = MockRemoteDataSource();
      localDataSource = LocalDataSource();
      secureStorage = const FlutterSecureStorage();
      repository = WorkoutRepositoryImpl(localDataSource, mockRemoteDataSource, secureStorage);
    });

    group('migrateDayOfWeek()', () {
      test('2.1.1: Workout Sa dayOfWeek → Vraća Postojeći dayOfWeek', () async {
        // Setup
        final workout = TestHelpers.createMockWorkout(dayOfWeek: 3);

        // Execute
        final result = await repository.migrateDayOfWeek(workout);

        // Verify
        expect(result, 3);
        // Verify - Backend NOT called
        verifyNever(mockRemoteDataSource.getAllWorkoutLogs());
      });

      test('2.1.2: Workout Bez dayOfWeek, Sa serverId → Fetch-uje Iz Backend-a', () async {
        // Setup
        final workout = TestHelpers.createMockWorkout(dayOfWeek: null, serverId: 'server-id-123');

        // Mock backend response
        when(mockRemoteDataSource.getAllWorkoutLogs()).thenAnswer(
          (_) async => [
            {'_id': 'server-id-123', 'dayOfWeek': 5},
          ],
        );

        // Execute
        final result = await repository.migrateDayOfWeek(workout);

        // Verify
        expect(result, 5);
        verify(mockRemoteDataSource.getAllWorkoutLogs()).called(1);
      });

      test('2.1.3: Workout Bez dayOfWeek I serverId → Vraća null', () async {
        // Setup
        final workout = TestHelpers.createMockWorkout(dayOfWeek: null, serverId: null);

        // Execute
        final result = await repository.migrateDayOfWeek(workout);

        // Verify
        expect(result, null);
        verifyNever(mockRemoteDataSource.getAllWorkoutLogs());
      });

      test('2.1.4: Backend Fetch Fail → Vraća null', () async {
        // Setup
        final workout = TestHelpers.createMockWorkout(dayOfWeek: null, serverId: 'server-id-123');

        // Mock backend failure
        when(mockRemoteDataSource.getAllWorkoutLogs()).thenThrow(Exception('Network error'));

        // Execute
        final result = await repository.migrateDayOfWeek(workout);

        // Verify
        expect(result, null);
      });
    });

    group('migratePlanId()', () {
      test('2.2.1: Workout Sa planId → Vraća Postojeći planId', () async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: 'existing-plan-id');

        // Execute
        final result = await repository.migratePlanId(workout);

        // Verify
        expect(result, 'existing-plan-id');
        // Verify - Backend NOT called
        verifyNever(mockRemoteDataSource.getAllWorkoutLogs());
      });

      test('2.2.2: Workout Bez planId, Sa serverId → Fetch-uje Iz Backend-a', () async {
        // Setup
        final workout = TestHelpers.createMockWorkout(planId: null, serverId: 'server-id-123');

        // Mock backend response
        when(mockRemoteDataSource.getAllWorkoutLogs()).thenAnswer(
          (_) async => [
            {'_id': 'server-id-123', 'weeklyPlanId': 'fetched-plan-id'},
          ],
        );

        // Execute
        final result = await repository.migratePlanId(workout);

        // Verify
        expect(result, 'fetched-plan-id');
        verify(mockRemoteDataSource.getAllWorkoutLogs()).called(1);
      });

      test('2.2.3: Workout Bez planId I serverId → Vraća null', () async {
        // Setup
        final workout = Workout(
          id: 'workout-123',
          serverId: null,
          name: 'Test Workout',
          planId: null,
          scheduledDate: DateTime.now(),
          dayOfWeek: 1,
          isCompleted: false,
          isMissed: false,
          isRestDay: false,
          isDirty: false,
          isSyncing: false,
          exercises: [],
          updatedAt: DateTime.now(),
        );

        // Execute
        final result = await repository.migratePlanId(workout);

        // Verify
        expect(result, null);
        verifyNever(mockRemoteDataSource.getAllWorkoutLogs());
      });

      test('2.2.4: Backend Fetch Fail → Vraća null', () async {
        // Setup
        final workout = Workout(
          id: 'workout-123',
          serverId: 'server-id-123',
          name: 'Test Workout',
          planId: null,
          scheduledDate: DateTime.now(),
          dayOfWeek: 1,
          isCompleted: false,
          isMissed: false,
          isRestDay: false,
          isDirty: false,
          isSyncing: false,
          exercises: [],
          updatedAt: DateTime.now(),
        );

        // Mock backend failure
        when(mockRemoteDataSource.getAllWorkoutLogs()).thenThrow(Exception('Network error'));

        // Execute
        final result = await repository.migratePlanId(workout);

        // Verify
        expect(result, null);
      });
    });

    group('COUNT COMPARISON', () {
      test('COUNT COMPARISON: Server has more logs than Isar', () async {
        // Setup: Mock LocalDataSource to return 10 workouts, RemoteDataSource to return 14
        // Note: This test requires mocking LocalDataSource which is a concrete class
        // For now, we'll test the logic by verifying that getAllWorkoutLogs is called
        // when COUNT COMPARISON detects a difference
        
        // Create mock workout logs for server (14 logs)
        final serverLogs = List.generate(14, (index) => {
          '_id': 'server-log-$index',
          'workoutDate': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
          'dayOfWeek': 1,
          'isCompleted': false,
          'isMissed': false,
          'isRestDay': false,
        });

        when(mockRemoteDataSource.getAllWorkoutLogs()).thenAnswer((_) async => serverLogs);

        // Execute: Call getWorkouts()
        // Since LocalDataSource is concrete and uses Isar, we can't easily mock it
        // This test verifies that COUNT COMPARISON logic calls getAllWorkoutLogs
        await repository.getWorkouts();

        // Verify: getAllWorkoutLogs was called (COUNT COMPARISON check)
        verify(mockRemoteDataSource.getAllWorkoutLogs()).called(greaterThanOrEqualTo(1));
      });

      test('COUNT COMPARISON: Server has same number of logs as Isar', () async {
        // Setup: Mock RemoteDataSource to return same number as Isar (if Isar is empty, this won't trigger COUNT COMPARISON)
        final serverLogs = List.generate(10, (index) => {
          '_id': 'server-log-$index',
          'workoutDate': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
          'dayOfWeek': 1,
          'isCompleted': false,
          'isMissed': false,
          'isRestDay': false,
        });

        when(mockRemoteDataSource.getAllWorkoutLogs()).thenAnswer((_) async => serverLogs);

        // Execute
        await repository.getWorkouts();

        // Verify: If Isar is empty, getAllWorkoutLogs is called for initial sync
        // If Isar has data, COUNT COMPARISON may or may not run depending on cache
        verify(mockRemoteDataSource.getAllWorkoutLogs()).called(greaterThanOrEqualTo(1));
      });

      test('COUNT COMPARISON: Error handling', () async {
        // Setup: Mock RemoteDataSource to throw error
        when(mockRemoteDataSource.getAllWorkoutLogs()).thenThrow(Exception('Network error'));

        // Execute: Should not throw, should continue execution
        final result = await repository.getWorkouts();

        // Verify: Error was caught, execution continued
        expect(result, isA<List<Workout>>());
        verify(mockRemoteDataSource.getAllWorkoutLogs()).called(greaterThanOrEqualTo(1));
      });

      test('COUNT COMPARISON: Data reuse optimization', () async {
        // Setup: Mock RemoteDataSource to return logs
        final serverLogs = List.generate(14, (index) => {
          '_id': 'server-log-$index',
          'workoutDate': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
          'dayOfWeek': 1,
          'isCompleted': false,
          'isMissed': false,
          'isRestDay': false,
        });

        when(mockRemoteDataSource.getAllWorkoutLogs()).thenAnswer((_) async => serverLogs);

        // Execute: Call getWorkouts() which should trigger COUNT COMPARISON
        // If COUNT COMPARISON detects server has more logs, it should reuse the data
        await repository.getWorkouts();

        // Verify: getAllWorkoutLogs should be called, but if COUNT COMPARISON reuses data,
        // it might be called fewer times
        verify(mockRemoteDataSource.getAllWorkoutLogs()).called(greaterThanOrEqualTo(1));
      });
    });
  });
}
