import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote_data_source.dart';

/// Service for centralized admin plan operations
/// Handles all plan CRUD operations with consistent error handling and logging
class AdminPlanService {
  final RemoteDataSource _remoteDataSource;

  AdminPlanService(this._remoteDataSource);

  /// Get all plans
  Future<List<Map<String, dynamic>>> getAllPlans() async {
    try {
      debugPrint('[AdminPlanService] Fetching all plans');
      // Note: RemoteDataSource doesn't have getPlans, using admin controller instead
      // This method is a placeholder for future implementation
      throw UnimplementedError('Use AdminController.getPlans instead');
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to fetch plans: $e');
      rethrow;
    }
  }

  /// Get plan by ID
  Future<Map<String, dynamic>> getPlanById(String planId) async {
    try {
      debugPrint('[AdminPlanService] Fetching plan: $planId');
      final plan = await _remoteDataSource.getPlanById(planId);
      debugPrint('[AdminPlanService] ✓ Fetched plan: ${plan['name']}');
      return plan;
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to fetch plan $planId: $e');
      rethrow;
    }
  }

  /// Create new plan
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData) async {
    try {
      debugPrint('[AdminPlanService] Creating plan: ${planData['name']}');
      final result = await _remoteDataSource.createPlan(planData);
      debugPrint('[AdminPlanService] ✓ Created plan: ${result['_id']}');
      return result;
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to create plan: $e');
      rethrow;
    }
  }

  /// Update existing plan
  Future<Map<String, dynamic>> updatePlan(
    String planId,
    Map<String, dynamic> planData,
  ) async {
    try {
      debugPrint('[AdminPlanService] Updating plan: $planId');
      debugPrint('[AdminPlanService] → Plan data: ${planData.keys.join(', ')}');
      final result = await _remoteDataSource.updatePlan(planId, planData);
      debugPrint('[AdminPlanService] ✓ Updated plan: $planId');
      return result;
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to update plan $planId: $e');
      rethrow;
    }
  }

  /// Delete plan
  Future<void> deletePlan(String planId) async {
    try {
      debugPrint('[AdminPlanService] Deleting plan: $planId');
      await _remoteDataSource.deletePlan(planId);
      debugPrint('[AdminPlanService] ✓ Deleted plan: $planId');
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to delete plan $planId: $e');
      rethrow;
    }
  }

  /// Duplicate plan
  Future<Map<String, dynamic>> duplicatePlan(String planId) async {
    try {
      debugPrint('[AdminPlanService] Duplicating plan: $planId');
      final result = await _remoteDataSource.duplicatePlan(planId);
      debugPrint('[AdminPlanService] ✓ Duplicated plan: ${result['_id']}');
      return result;
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to duplicate plan $planId: $e');
      rethrow;
    }
  }

  /// Assign plan to clients
  Future<void> assignPlanToClients(
    String planId,
    List<String> clientIds,
    DateTime startDate,
  ) async {
    try {
      debugPrint('[AdminPlanService] Assigning plan $planId to ${clientIds.length} clients');
      await _remoteDataSource.assignPlanToClients(
        planId,
        clientIds,
        startDate,
      );
      debugPrint('[AdminPlanService] ✓ Assigned plan to clients');
    } catch (e) {
      debugPrint('[AdminPlanService] ✗ Failed to assign plan: $e');
      rethrow;
    }
  }
}

