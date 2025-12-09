import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import 'auth_controller.dart';

part 'plan_controller.g.dart';

// Repository Provider
@riverpod
PlanRepository planRepository(PlanRepositoryRef ref) {
  ref.keepAlive();
  final localDataSource = LocalDataSource();
  final dio = Dio();
  const storage = FlutterSecureStorage();
  final remoteDataSource = RemoteDataSource(dio, storage);
  return PlanRepositoryImpl(localDataSource, remoteDataSource);
}

// Current Plan Provider
@riverpod
Future<Plan?> currentPlan(CurrentPlanRef ref) async {
  print('═══════════════════════════════════════════════════════════');
  print('[PlanController] currentPlanProvider START');
  
  // Watch auth state only - this should trigger rebuild when user changes
  final authState = ref.watch(authControllerProvider);
  final user = authState.valueOrNull;
  
  if (user == null) {
    print('[PlanController] ✗ User is null - returning null');
    print('═══════════════════════════════════════════════════════════');
    return null;
  }
  
  print('[PlanController] → User ID: ${user.id}');
  print('[PlanController] → User role: ${user.role}');
  
  // Admin and Trainer don't have "current plan" - only CLIENT does
  if (user.role != 'CLIENT') {
    print('[PlanController] → User is ${user.role} - skipping getCurrentPlan (only for CLIENT)');
    print('═══════════════════════════════════════════════════════════');
    return null;
  }
  
  print('[PlanController] → Getting plan repository...');
  
  // Use read() instead of watch() to avoid rebuild loops
  final planRepo = ref.read(planRepositoryProvider);
  print('[PlanController] → Repository obtained, calling getCurrentPlan(${user.id})...');
  
  try {
    final result = await planRepo.getCurrentPlan(user.id);
    
    if (result != null) {
      print('[PlanController] ✓ Plan found: ${result.name} (ID: ${result.id})');
    } else {
      print('[PlanController] ✗ No plan found');
    }
    
    print('═══════════════════════════════════════════════════════════');
    return result;
  } catch (e, stackTrace) {
    // Silently handle errors for non-CLIENT roles
    print('[PlanController] ✗ Error in getCurrentPlan (silently handled): $e');
    print('═══════════════════════════════════════════════════════════');
    return null; // Return null instead of rethrowing
  }
}

// Plan by ID Provider
@riverpod
Future<Plan?> planById(PlanByIdRef ref, String planId) async {
  final planRepo = ref.watch(planRepositoryProvider);
  return await planRepo.getPlanById(planId);
}

// All Plans Provider
@riverpod
Future<List<Plan>> allPlans(AllPlansRef ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];
  
  final planRepo = ref.watch(planRepositoryProvider);
  return await planRepo.getAllPlans(user.id, user.role);
}

// Plans by Trainer Provider
@riverpod
Future<List<Plan>> plansByTrainer(PlansByTrainerRef ref, String trainerId) async {
  final planRepo = ref.watch(planRepositoryProvider);
  return await planRepo.getPlansByTrainer(trainerId);
}

