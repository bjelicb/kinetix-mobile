import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/ai_message.dart';
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
  late RemoteDataSource _remoteDataSource;

  @override
  FutureOr<Map<String, dynamic>> build() async {
    _repository = ref.read(adminRepositoryProvider);
    final storage = FlutterSecureStorage();
    final dio = Dio();
    _remoteDataSource = RemoteDataSource(dio, storage);
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

  /// Generate AI message for a client
  Future<void> generateAIMessage({
    required String clientId,
    required AIMessageTrigger trigger,
    String? customMessage,
    AIMessageTone? tone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert Flutter enum to backend format (camelCase -> UPPER_SNAKE_CASE)
      String triggerString = _triggerToBackendFormat(trigger);
      String? toneString = tone != null ? _toneToBackendFormat(tone) : null;
      
      await _remoteDataSource.generateAIMessage(
        clientId: clientId,
        trigger: triggerString,
        customMessage: customMessage,
        tone: toneString,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('[AdminController] Error generating AI message: $e');
      throw Exception('Failed to generate AI message: ${e.toString()}');
    }
  }

  /// Convert Flutter AIMessageTone enum to backend format
  String _toneToBackendFormat(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.aggressive:
        return 'AGGRESSIVE';
      case AIMessageTone.empathetic:
        return 'EMPATHETIC';
      case AIMessageTone.motivational:
        return 'MOTIVATIONAL';
      case AIMessageTone.warning:
        return 'WARNING';
    }
  }

  /// Convert Flutter AIMessageTrigger enum to backend format
  /// missedWorkouts -> MISSED_WORKOUTS
  /// weightSpike -> WEIGHT_SPIKE
  /// sickDay -> SICK_DAY
  /// streak -> STREAK
  String _triggerToBackendFormat(AIMessageTrigger trigger) {
    switch (trigger) {
      case AIMessageTrigger.missedWorkouts:
        return 'MISSED_WORKOUTS';
      case AIMessageTrigger.streak:
        return 'STREAK';
      case AIMessageTrigger.weightSpike:
        return 'WEIGHT_SPIKE';
      case AIMessageTrigger.sickDay:
        return 'SICK_DAY';
    }
  }

  /// Get all AI messages (using batch endpoint)
  Future<List<AIMessage>> getAllAIMessages() async {
    try {
      debugPrint('[AdminController] getAllAIMessages - using batch endpoint');
      
      // Use batch endpoint to get all messages at once
      final messagesData = await _remoteDataSource.getAllAIMessages();
      
      // Map to AIMessage entities
      final messages = messagesData.map((data) => AIMessage.fromJson(data)).toList();
      
      debugPrint('[AdminController] ✓ Loaded ${messages.length} messages from batch endpoint');
      
      // Messages are already sorted by backend (newest first)
      return messages;
    } catch (e) {
      debugPrint('[AdminController] Error getting all AI messages: $e');
      throw Exception('Failed to get AI messages: ${e.toString()}');
    }
  }
}
