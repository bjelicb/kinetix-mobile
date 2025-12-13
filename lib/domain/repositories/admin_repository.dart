import '../entities/user.dart';

abstract class AdminRepository {
  Future<List<User>> getAllUsers();
  Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  });
  Future<Map<String, dynamic>> getAdminStats();
  Future<void> assignClientToTrainer({
    required String clientId,
    String? trainerId, // Optional: null means unassign
  });
  Future<List<Map<String, dynamic>>> getAllPlans();
  Future<Map<String, dynamic>> getPlanById(String planId);
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData);
  Future<Map<String, dynamic>> updatePlan(String planId, Map<String, dynamic> planData);
  Future<void> deletePlan(String planId);
  Future<Map<String, dynamic>> assignPlanToClients(String planId, List<String> clientIds, DateTime startDate);
  Future<Map<String, dynamic>> duplicatePlan(String planId);
  Future<void> cancelPlan(String planId, String clientId);
  Future<List<Map<String, dynamic>>> getAllWorkouts();
  Future<Map<String, dynamic>> getWorkoutStats();
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
  });
  Future<void> deleteUser(String userId);
  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  });
  Future<void> updateWorkoutStatus({
    required String workoutId,
    bool? isCompleted,
    bool? isMissed,
  });
  Future<void> deleteWorkout(String workoutId);
}
