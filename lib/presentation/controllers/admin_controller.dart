import 'dart:developer' as developer;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/datasources/remote_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

part 'admin_controller.g.dart';

@riverpod
AdminRepository adminRepository(AdminRepositoryRef ref) {
  final storage = FlutterSecureStorage();
  final dio = Dio();
  final remoteDataSource = RemoteDataSource(dio, storage);
  return AdminRepositoryImpl(remoteDataSource);
}

@riverpod
class AdminController extends _$AdminController {
  late AdminRepository _repository;

  @override
  FutureOr<Map<String, dynamic>> build() async {
    _repository = ref.read(adminRepositoryProvider);
    return await _repository.getAdminStats();
  }

  Future<List<User>> getAllUsers() async {
    try {
      return await _repository.getAllUsers();
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final user = await _repository.createUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      // Refresh stats after creating user
      ref.invalidateSelf();
      return user;
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<void> assignClientToTrainer({
    required String clientId,
    String? trainerId, // Optional: null means unassign
  }) async {
    try {
      await _repository.assignClientToTrainer(clientId: clientId, trainerId: trainerId);
      // Refresh stats after assignment
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to assign client: ${e.toString()}');
    }
  }

  Future<void> refreshStats() async {
    ref.invalidateSelf();
  }

  Future<List<Map<String, dynamic>>> getAllPlans() async {
    try {
      return await _repository.getAllPlans();
    } catch (e) {
      throw Exception('Failed to load plans: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getPlanById(String planId) async {
    try {
      return await _repository.getPlanById(planId);
    } catch (e) {
      throw Exception('Failed to load plan: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData) async {
    try {
      final plan = await _repository.createPlan(planData);
      ref.invalidateSelf();
      return plan;
    } catch (e) {
      throw Exception('Failed to create plan: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updatePlan(String planId, Map<String, dynamic> planData) async {
    try {
      final plan = await _repository.updatePlan(planId, planData);
      ref.invalidateSelf();
      return plan;
    } catch (e) {
      throw Exception('Failed to update plan: ${e.toString()}');
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await _repository.deletePlan(planId);
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to delete plan: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> assignPlanToClients(String planId, List<String> clientIds, DateTime startDate) async {
    try {
      final result = await _repository.assignPlanToClients(planId, clientIds, startDate);
      ref.invalidateSelf();
      return result;
    } catch (e) {
      throw Exception('Failed to assign plan: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> duplicatePlan(String planId) async {
    try {
      final plan = await _repository.duplicatePlan(planId);
      ref.invalidateSelf();
      return plan;
    } catch (e) {
      throw Exception('Failed to duplicate plan: ${e.toString()}');
    }
  }

  Future<void> cancelPlan(String planId, String clientId) async {
    developer.log('[AdminController] cancelPlan START - planId: $planId, clientId: $clientId', name: 'AdminController');
    try {
      await _repository.cancelPlan(planId, clientId);
      ref.invalidateSelf();
      developer.log('[AdminController] cancelPlan SUCCESS - Plan cancelled for client $clientId', name: 'AdminController');
    } catch (e) {
      developer.log('[AdminController] cancelPlan ERROR: $e', name: 'AdminController', error: e);
      throw Exception('Failed to cancel plan: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    developer.log('[AdminController] getAllWorkouts START - calling repository...', name: 'AdminController');
    try {
      final workouts = await _repository.getAllWorkouts();
      developer.log('[AdminController] getAllWorkouts SUCCESS - received ${workouts.length} workouts', name: 'AdminController');

      if (workouts.isNotEmpty) {
        final sampleWorkout = workouts.first;
        developer.log(
          '[AdminController] getAllWorkouts - sample workout: id=${sampleWorkout['_id']}, clientId=${sampleWorkout['clientId']}, planId=${sampleWorkout['weeklyPlanId']}',
          name: 'AdminController',
        );
      }

      return workouts;
    } catch (e) {
      developer.log('[AdminController] getAllWorkouts ERROR: $e', name: 'AdminController', error: e);
      throw Exception('Failed to load workouts: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      return await _repository.getWorkoutStats();
    } catch (e) {
      throw Exception('Failed to load workout stats: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
  }) async {
    try {
      final result = await _repository.updateUser(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
      );
      ref.invalidateSelf();
      return result;
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      developer.log('[AdminController] deleteUser called with ID: $userId', name: 'AdminController');
      await _repository.deleteUser(userId);
      ref.invalidateSelf();
      developer.log('[AdminController] deleteUser completed successfully', name: 'AdminController');
    } catch (e, stackTrace) {
      developer.log('[AdminController] ERROR deleting user: $e', name: 'AdminController', error: e);
      developer.log('[AdminController] Stack trace: $stackTrace', name: 'AdminController');
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  Future<void> updateUserStatus({required String userId, required bool isActive}) async {
    try {
      await _repository.updateUserStatus(userId: userId, isActive: isActive);
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to update user status: ${e.toString()}');
    }
  }

  Future<void> updateWorkoutStatus({required String workoutId, bool? isCompleted, bool? isMissed}) async {
    try {
      await _repository.updateWorkoutStatus(workoutId: workoutId, isCompleted: isCompleted, isMissed: isMissed);
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to update workout status: ${e.toString()}');
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _repository.deleteWorkout(workoutId);
      ref.invalidateSelf();
    } catch (e, stackTrace) {
      // Log detailed error for debugging
      developer.log('ERROR [AdminController.deleteWorkout]: Failed to delete workout $workoutId', name: 'AdminController');
      developer.log('Error: $e', name: 'AdminController', error: e);
      developer.log('Stack trace: $stackTrace', name: 'AdminController');
      throw Exception('Failed to delete workout: ${e.toString()}');
    }
  }
}
