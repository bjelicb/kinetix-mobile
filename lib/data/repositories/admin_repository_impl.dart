import 'dart:developer' as developer;
import '../../domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/remote_data_source.dart';
import '../mappers/user_mapper.dart';
import '../models/user_collection.dart' if (dart.library.html) '../models/user_collection_stub.dart';

class AdminRepositoryImpl implements AdminRepository {
  final RemoteDataSource _remoteDataSource;
  
  AdminRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<List<User>> getAllUsers() async {
    try {
      final usersData = await _remoteDataSource.getAllUsers();
      
      if (usersData.isEmpty) {
        return [];
      }
      
      final users = <User>[];
      
      for (final userData in usersData) {
        try {
          // Handle trainer assignment - could be trainerId or trainerName
          String? trainerName;
          String? trainerId;
          
          if (userData['trainerName'] != null && userData['trainerName'].toString().isNotEmpty) {
            trainerName = userData['trainerName'].toString();
          }
          
          if (userData['trainerId'] != null && userData['trainerId'].toString().isNotEmpty) {
            trainerId = userData['trainerId'].toString();
          }
          
          // Safely extract user data with null checks
          final serverId = userData['_id']?.toString() ?? userData['id']?.toString();
          final email = userData['email']?.toString() ?? '';
          final role = userData['role']?.toString() ?? 'CLIENT';
          final firstName = userData['firstName']?.toString() ?? '';
          final lastName = userData['lastName']?.toString() ?? '';
          final isActive = userData['isActive'] as bool? ?? true;
          
          if (serverId == null || serverId.isEmpty || email.isEmpty) {
            continue;
          }
          
          final userCollection = UserCollection()
            ..serverId = serverId
            ..email = email
            ..role = role
            ..name = '$firstName $lastName'.trim().isEmpty 
                ? email.split('@').first 
                : '$firstName $lastName'.trim()
            ..trainerName = trainerName
            ..trainerId = trainerId
            ..clientProfileId = userData['clientProfileId'] as String?
            ..isActive = isActive
            ..lastSync = DateTime.now();
          
          users.add(UserMapper.toEntity(userCollection));
        } catch (e) {
          // Skip invalid user data
          continue;
        }
      }
      
      return users;
    } catch (e) {
      developer.log('Error in getAllUsers: $e', name: 'AdminRepository', error: e);
      final errorMessage = e.toString();
      if (errorMessage.contains('Network') || errorMessage.contains('timeout')) {
        throw Exception('Network error: Unable to connect to server. Please check your connection.');
      } else if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
        throw Exception('Authentication error: Please log in again.');
      } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
        throw Exception('Access denied: You do not have permission to view users.');
      } else {
        throw Exception('Failed to load users: ${errorMessage.replaceAll('Exception: ', '')}');
      }
    }
  }
  
  @override
  Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final responseData = await _remoteDataSource.createUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      
      // Register endpoint returns { user: {...} }
      final userData = responseData['user'] as Map<String, dynamic>? ?? responseData;
      
      final userCollection = UserCollection()
        ..serverId = userData['_id']?.toString() ?? userData['id']?.toString() ?? ''
        ..email = userData['email']?.toString() ?? ''
        ..role = userData['role']?.toString() ?? 'CLIENT'
        ..name = '$firstName $lastName'.trim()
        ..lastSync = DateTime.now();
      
      return UserMapper.toEntity(userCollection);
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      return await _remoteDataSource.getAdminStats();
    } catch (e) {
      throw Exception('Failed to get admin stats: ${e.toString()}');
    }
  }
  
  @override
  Future<void> assignClientToTrainer({
    required String clientId,
    String? trainerId, // Optional: null means unassign
  }) async {
    try {
      await _remoteDataSource.assignClientToTrainer(
        clientId: clientId,
        trainerId: trainerId,
      );
    } catch (e) {
      throw Exception('Failed to assign client: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPlans() async {
    try {
      return await _remoteDataSource.getAllPlans();
    } catch (e) {
      throw Exception('Failed to get plans: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getPlanById(String planId) async {
    try {
      return await _remoteDataSource.getPlanById(planId);
    } catch (e) {
      throw Exception('Failed to get plan: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData) async {
    try {
      return await _remoteDataSource.createPlan(planData);
    } catch (e) {
      throw Exception('Failed to create plan: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updatePlan(String planId, Map<String, dynamic> planData) async {
    try {
      return await _remoteDataSource.updatePlan(planId, planData);
    } catch (e) {
      throw Exception('Failed to update plan: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    try {
      await _remoteDataSource.deletePlan(planId);
    } catch (e) {
      throw Exception('Failed to delete plan: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> assignPlanToClients(String planId, List<String> clientIds, DateTime startDate) async {
    try {
      return await _remoteDataSource.assignPlanToClients(planId, clientIds, startDate);
    } catch (e) {
      throw Exception('Failed to assign plan: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> duplicatePlan(String planId) async {
    try {
      return await _remoteDataSource.duplicatePlan(planId);
    } catch (e) {
      throw Exception('Failed to duplicate plan: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    try {
      return await _remoteDataSource.getAllWorkouts();
    } catch (e) {
      throw Exception('Failed to get workouts: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      return await _remoteDataSource.getWorkoutStats();
    } catch (e) {
      throw Exception('Failed to get workout stats: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
  }) async {
    try {
      return await _remoteDataSource.updateUser(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
      );
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    developer.log('[AdminRepositoryImpl] deleteUser called with ID: $userId');
    try {
      await _remoteDataSource.deleteUser(userId);
      developer.log('[AdminRepositoryImpl] deleteUser successful');
    } catch (e, stackTrace) {
      developer.log('[AdminRepositoryImpl] ERROR deleting user: $e');
      developer.log('[AdminRepositoryImpl] Stack trace: $stackTrace');
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await _remoteDataSource.updateUserStatus(
        userId: userId,
        isActive: isActive,
      );
    } catch (e) {
      throw Exception('Failed to update user status: ${e.toString()}');
    }
  }

  @override
  Future<void> updateWorkoutStatus({
    required String workoutId,
    bool? isCompleted,
    bool? isMissed,
  }) async {
    try {
      await _remoteDataSource.updateWorkoutStatus(
        workoutId: workoutId,
        isCompleted: isCompleted,
        isMissed: isMissed,
      );
    } catch (e) {
      throw Exception('Failed to update workout status: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    try {
      developer.log('[AdminRepository] deleteWorkout called with ID: $workoutId');
      await _remoteDataSource.deleteWorkout(workoutId);
      developer.log('[AdminRepository] deleteWorkout completed successfully');
    } catch (e, stackTrace) {
      developer.log('[AdminRepository] ERROR deleting workout: $e');
      developer.log('[AdminRepository] Stack trace: $stackTrace');
      throw Exception('Failed to delete workout: ${e.toString()}');
    }
  }
}
