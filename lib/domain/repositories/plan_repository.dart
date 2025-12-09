import '../entities/plan.dart';

abstract class PlanRepository {
  /// Get the current active plan for a user
  Future<Plan?> getCurrentPlan(String userId);
  
  /// Get a specific plan by ID
  Future<Plan?> getPlanById(String planId);
  
  /// Get all plans for a user (filtered by role)
  Future<List<Plan>> getAllPlans(String userId, String userRole);
  
  /// Save a plan locally
  Future<void> savePlan(Plan plan);
  
  /// Get all plans created by a specific trainer
  Future<List<Plan>> getPlansByTrainer(String trainerId);
}

