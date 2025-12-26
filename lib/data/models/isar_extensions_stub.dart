// Stub Isar extensions for web platform
// These methods will never be called (kIsWeb guards) but need to compile
import 'package:isar/isar.dart';
// Import stub files for type definitions
import 'user_collection_stub.dart';
import 'workout_collection_stub.dart';
import 'exercise_collection_stub.dart';
import 'checkin_collection_stub.dart';
import 'plan_collection_stub.dart';
import 'ai_message_collection_stub.dart';
// Re-export stub files so types are available to other files
export 'user_collection_stub.dart';
export 'workout_collection_stub.dart';
export 'exercise_collection_stub.dart';
export 'checkin_collection_stub.dart';
export 'plan_collection_stub.dart';
export 'ai_message_collection_stub.dart';

// Stub query builder for type compatibility
class StubQueryBuilder<T> {
  StubQueryBuilder<T> serverIdEqualTo(String value) => this;
  StubQueryBuilder<T> isDirtyEqualTo(bool value) => this;
  StubQueryBuilder<T> isSyncedEqualTo(bool value) => this;
  StubQueryBuilder<T> photoUrlIsNull() => this;
  StubQueryBuilder<T> planIdEqualTo(String value) => this;
  StubQueryBuilder<T> trainerIdEqualTo(String value) => this;
  StubQueryBuilder<T> scheduledDateGreaterThan(DateTime value) => this;
  StubQueryBuilder<T> clientIdEqualTo(String value) => this;
  Future<List<T>> findAll() async => [];
  Future<T?> findFirst() async => null;
}

// Stub collection wrapper
class StubCollection<T> {
  StubQueryBuilder<T> filter() => StubQueryBuilder<T>();
  StubQueryBuilder<T> where() => StubQueryBuilder<T>();
  Future<T?> get(int id) async => null;
  Future<void> put(T item) async {}
  Future<void> delete(int id) async {}
}

// Extension on Isar for web - provides stub collection getters
extension UserCollectionStub on Isar {
  StubCollection<UserCollection> get userCollections => StubCollection<UserCollection>();
}

extension WorkoutCollectionStub on Isar {
  StubCollection<WorkoutCollection> get workoutCollections => StubCollection<WorkoutCollection>();
}

extension ExerciseCollectionStub on Isar {
  StubCollection<ExerciseCollection> get exerciseCollections => StubCollection<ExerciseCollection>();
}

extension CheckInCollectionStub on Isar {
  StubCollection<CheckInCollection> get checkInCollections => StubCollection<CheckInCollection>();
}

extension PlanCollectionStub on Isar {
  StubCollection<PlanCollection> get planCollections => StubCollection<PlanCollection>();
}

extension AIMessageCollectionStub on Isar {
  StubCollection<AIMessageCollection> get aIMessageCollections => StubCollection<AIMessageCollection>();
}

