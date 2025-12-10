import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote_data_source.dart';

/// Service for centralized admin user operations
/// Handles all user CRUD operations with consistent error handling and logging
class AdminUserService {
  final RemoteDataSource _remoteDataSource;

  AdminUserService(this._remoteDataSource);

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      debugPrint('[AdminUserService] Fetching all users');
      final users = await _remoteDataSource.getAllUsers();
      debugPrint('[AdminUserService] ✓ Fetched ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to fetch users: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      debugPrint('[AdminUserService] Fetching user: $userId');
      // Note: RemoteDataSource doesn't have getUserById yet, using getAllUsers
      final users = await _remoteDataSource.getAllUsers();
      final user = users.firstWhere(
        (u) => u['_id'] == userId,
        orElse: () => throw Exception('User not found'),
      );
      debugPrint('[AdminUserService] ✓ Fetched user: ${user['name']}');
      return user;
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to fetch user $userId: $e');
      rethrow;
    }
  }

  /// Create new user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      debugPrint('[AdminUserService] Creating user: ${userData['name']}');
      final result = await _remoteDataSource.createUser(
        email: userData['email'] as String,
        password: userData['password'] as String,
        firstName: userData['firstName'] as String,
        lastName: userData['lastName'] as String,
        role: userData['role'] as String,
      );
      debugPrint('[AdminUserService] ✓ Created user: ${result['_id']}');
      return result;
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to create user: $e');
      rethrow;
    }
  }

  /// Update existing user
  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      debugPrint('[AdminUserService] Updating user: $userId');
      final result = await _remoteDataSource.updateUser(
        userId: userId,
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
        email: userData['email'] as String?,
        role: userData['role'] as String?,
      );
      debugPrint('[AdminUserService] ✓ Updated user: $userId');
      return result;
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to update user $userId: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('[AdminUserService] Deleting user: $userId');
      await _remoteDataSource.deleteUser(userId);
      debugPrint('[AdminUserService] ✓ Deleted user: $userId');
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to delete user $userId: $e');
      rethrow;
    }
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      debugPrint('[AdminUserService] Updating user $userId status to ${isActive ? "active" : "inactive"}');
      await _remoteDataSource.updateUserStatus(
        userId: userId,
        isActive: isActive,
      );
      debugPrint('[AdminUserService] ✓ Updated user status');
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to update user status: $e');
      rethrow;
    }
  }

  /// Get trainers only
  Future<List<Map<String, dynamic>>> getTrainers() async {
    try {
      debugPrint('[AdminUserService] Fetching trainers');
      final users = await _remoteDataSource.getAllUsers();
      final trainers = users.where((u) => u['role'] == 'TRAINER').toList();
      debugPrint('[AdminUserService] ✓ Fetched ${trainers.length} trainers');
      return trainers;
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to fetch trainers: $e');
      rethrow;
    }
  }

  /// Get clients only
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      debugPrint('[AdminUserService] Fetching clients');
      final users = await _remoteDataSource.getAllUsers();
      final clients = users.where((u) => u['role'] == 'CLIENT').toList();
      debugPrint('[AdminUserService] ✓ Fetched ${clients.length} clients');
      return clients;
    } catch (e) {
      debugPrint('[AdminUserService] ✗ Failed to fetch clients: $e');
      rethrow;
    }
  }
}

