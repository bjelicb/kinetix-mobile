import '../../domain/entities/plan.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../mappers/plan_mapper.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class PlanRepositoryImpl implements PlanRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource? _remoteDataSource;
  
  PlanRepositoryImpl(this._localDataSource, this._remoteDataSource);
  
  @override
  Future<Plan?> getCurrentPlan(String userId) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[PlanRepository] getCurrentPlan() START - userId: $userId');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    try {
      // Try to get current plan from remote first
      if (_remoteDataSource != null) {
        debugPrint('[PlanRepository] → RemoteDataSource is available');
        debugPrint('[PlanRepository] → Attempting to fetch plan from remote API...');
        try {
          final response = await _remoteDataSource!.getCurrentPlan();
          debugPrint('[PlanRepository] → Remote API response received');
          debugPrint('[PlanRepository] → Response keys: ${response.keys.toList()}');
          debugPrint('[PlanRepository] → Response isNotEmpty: ${response.isNotEmpty}');
          debugPrint('[PlanRepository] → Response has _id: ${response.containsKey('_id')}');
          debugPrint('[PlanRepository] → Response has id: ${response.containsKey('id')}');
          
          // Backend returns plan directly (not wrapped in 'plan' field)
          // Response can be null if no active plan, or the plan object itself
          if (response != null && response.isNotEmpty) {
            // Check if response is the plan object directly
            if (response.containsKey('_id') || response.containsKey('id')) {
              debugPrint('[PlanRepository] → Valid plan response detected, converting to entity...');
              final planId = response['_id']?.toString() ?? response['id']?.toString() ?? 'unknown';
              debugPrint('[PlanRepository] → Plan ID: $planId');
              debugPrint('[PlanRepository] → Plan name: ${response['name']}');
              
              final planEntity = PlanMapper.toEntity(response);
              debugPrint('[PlanRepository] → Plan entity created: ${planEntity.name}');
              debugPrint('[PlanRepository] → Workout days count: ${planEntity.workoutDays.length}');
              
              // Save to local database
              debugPrint('[PlanRepository] → Saving plan to local database...');
              final planCollection = PlanMapper.toCollection(planEntity);
              planCollection.isDirty = false;
              await _localDataSource.savePlan(planCollection);
              debugPrint('[PlanRepository] → Plan saved to local database');
              
              debugPrint('[PlanRepository] ✓ Current plan loaded from server: ${planEntity.name} (ID: ${planEntity.id})');
              debugPrint('═══════════════════════════════════════════════════════════');
              return planEntity;
            } else {
              debugPrint('[PlanRepository] ✗ Response is not a valid plan object (missing _id/id)');
            }
          } else {
            debugPrint('[PlanRepository] ✗ Response is null or empty');
          }
          
          debugPrint('[PlanRepository] ✗ No active plan found on server');
        } catch (e, stackTrace) {
          debugPrint('[PlanRepository] ✗ Error fetching current plan from server: $e');
          debugPrint('[PlanRepository] Stack trace: $stackTrace');
          // Fall through to local database
        }
      } else {
        debugPrint('[PlanRepository] → RemoteDataSource is null, skipping remote fetch');
      }
      
      // Try local database as fallback
      debugPrint('[PlanRepository] → Falling back to local database...');
      final allPlans = await _localDataSource.getAllPlans();
      debugPrint('[PlanRepository] → Local plans count: ${allPlans.length}');
      
      if (allPlans.isEmpty) {
        debugPrint('[PlanRepository] ✗ No plans found in local database');
        debugPrint('═══════════════════════════════════════════════════════════');
        return null;
      }
      
      // Return the most recently updated plan
      allPlans.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final latestPlan = PlanMapper.fromCollection(allPlans.first);
      debugPrint('[PlanRepository] ✓ Using latest local plan: ${latestPlan.name} (ID: ${latestPlan.id})');
      debugPrint('[PlanRepository] → Updated at: ${allPlans.first.updatedAt}');
      debugPrint('═══════════════════════════════════════════════════════════');
      return latestPlan;
      
    } catch (e, stackTrace) {
      debugPrint('[PlanRepository] ✗✗✗ ERROR getting current plan: $e');
      debugPrint('[PlanRepository] Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════════');
      return null;
    }
  }
  
  @override
  Future<Plan?> getPlanById(String planId) async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[PlanRepository] getPlanById() START - planId: $planId');
    try {
      // Try local database first (offline-first)
      debugPrint('[PlanRepository] → Checking local database...');
      final localPlan = await _localDataSource.getPlanById(planId);
      if (localPlan != null) {
        debugPrint('[PlanRepository] ✓ Plan found in local database: ${localPlan.name}');
        return PlanMapper.fromCollection(localPlan);
      }
      debugPrint('[PlanRepository] → Plan not found in local database');
      
      // Fetch from server if not found locally
      // For CLIENT users, try getCurrentPlan first (they can only access their assigned plan)
      if (_remoteDataSource != null) {
        debugPrint('[PlanRepository] → Fetching plan from server...');
        try {
          // Try getPlanById first (works for TRAINER/ADMIN)
          Map<String, dynamic>? planDto;
          try {
            planDto = await _remoteDataSource.getPlanById(planId);
            debugPrint('[PlanRepository] → Plan received from getPlanById endpoint');
          } catch (e) {
            debugPrint('[PlanRepository] → getPlanById failed (may be CLIENT role): $e');
            debugPrint('[PlanRepository] → Trying getCurrentPlan as fallback...');
            // If getPlanById fails (likely 403 Forbidden for CLIENT), try getCurrentPlan
            try {
              final currentPlanDto = await _remoteDataSource.getCurrentPlan();
              if (currentPlanDto.isNotEmpty) {
                final currentPlanId = currentPlanDto['_id']?.toString() ?? currentPlanDto['id']?.toString();
                if (currentPlanId == planId) {
                  debugPrint('[PlanRepository] → Current plan ID matches requested plan ID');
                  planDto = currentPlanDto;
                } else {
                  debugPrint('[PlanRepository] → Current plan ID ($currentPlanId) does not match requested ($planId)');
                }
              }
            } catch (currentPlanError) {
              debugPrint('[PlanRepository] → getCurrentPlan also failed: $currentPlanError');
            }
          }
          
          if (planDto != null && planDto.isNotEmpty) {
            debugPrint('[PlanRepository] → Plan DTO received, converting to entity...');
            debugPrint('[PlanRepository] → Plan DTO keys: ${planDto.keys.toList()}');
            final planEntity = PlanMapper.toEntity(planDto);
            debugPrint('[PlanRepository] → Plan entity created: ${planEntity.name}');
            
            // Save to local database
            debugPrint('[PlanRepository] → Saving plan to local database...');
            final planCollection = PlanMapper.toCollection(planEntity);
            planCollection.isDirty = false;
            await _localDataSource.savePlan(planCollection);
            debugPrint('[PlanRepository] → Plan saved to local database');
            
            debugPrint('[PlanRepository] ✓ Plan loaded from server: ${planEntity.name}');
            debugPrint('═══════════════════════════════════════════════════════════');
            return planEntity;
          } else {
            debugPrint('[PlanRepository] ✗ Plan DTO is null or empty');
          }
        } catch (e, stackTrace) {
          debugPrint('[PlanRepository] ✗ Error fetching plan from server: $e');
          debugPrint('[PlanRepository] Stack trace: $stackTrace');
        }
      } else {
        debugPrint('[PlanRepository] ✗ RemoteDataSource is null');
      }
      
      debugPrint('[PlanRepository] ✗ Plan not found');
      debugPrint('═══════════════════════════════════════════════════════════');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[PlanRepository] ✗✗✗ ERROR getting plan by ID: $e');
      debugPrint('[PlanRepository] Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════════');
      return null;
    }
  }
  
  @override
  Future<List<Plan>> getAllPlans(String userId, String userRole) async {
    try {
      // For ADMIN/TRAINER, fetch from server
      if (userRole == 'ADMIN' || userRole == 'TRAINER') {
        if (_remoteDataSource != null) {
          try {
            final plansDto = await _remoteDataSource.getAllPlans();
            final plans = <Plan>[];
            
            for (final planDto in plansDto) {
              try {
                final planEntity = PlanMapper.toEntity(planDto);
                plans.add(planEntity);
                
                // Save to local database
                final planCollection = PlanMapper.toCollection(planEntity);
                planCollection.isDirty = false;
                await _localDataSource.savePlan(planCollection);
              } catch (e) {
                debugPrint('[PlanRepository] Error processing plan: $e');
              }
            }
            
            return plans;
          } catch (e) {
            debugPrint('[PlanRepository] Error fetching plans from server: $e');
            // Fall through to local database
          }
        }
      }
      
      // Return local plans
      final localPlans = await _localDataSource.getAllPlans();
      return localPlans.map((c) => PlanMapper.fromCollection(c)).toList();
      
    } catch (e) {
      debugPrint('[PlanRepository] Error getting all plans: $e');
      return [];
    }
  }
  
  @override
  Future<void> savePlan(Plan plan) async {
    try {
      final planCollection = PlanMapper.toCollection(plan);
      planCollection.isDirty = true;
      planCollection.updatedAt = DateTime.now();
      
      await _localDataSource.savePlan(planCollection);
      
      // SyncManager will push this in background
      debugPrint('[PlanRepository] Plan saved locally: ${plan.id}');
    } catch (e) {
      debugPrint('[PlanRepository] Error saving plan: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Plan>> getPlansByTrainer(String trainerId) async {
    try {
      final localPlans = await _localDataSource.getPlansByTrainer(trainerId);
      return localPlans.map((c) => PlanMapper.fromCollection(c)).toList();
    } catch (e) {
      debugPrint('[PlanRepository] Error getting plans by trainer: $e');
      return [];
    }
  }
}

