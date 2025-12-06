import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../mappers/user_mapper.dart';
import '../models/user_collection.dart' if (dart.library.html) '../models/user_collection_stub.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _storage;
  
  AuthRepositoryImpl(this._localDataSource, this._remoteDataSource, FlutterSecureStorage storage)
      : _storage = storage;
  
  @override
  Future<User> login(String email, String password) async {
    try {
      // Use real API
      final response = await _remoteDataSource.login(email, password);
      
      // Tokens are already saved in RemoteDataSource.login()
      // Get user data from response
      final userData = response['user'] as Map<String, dynamic>;
      
      // Save user locally
      final userCollection = UserCollection()
        ..serverId = userData['_id'] as String? ?? userData['id'] as String
        ..email = userData['email'] as String
        ..role = userData['role'] as String
        ..name = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim()
        ..lastSync = DateTime.now();
      
      await _localDataSource.saveUser(userCollection);
      
      return UserMapper.toEntity(userCollection);
    } catch (e) {
      // Re-throw with better error message
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  @override
  Future<User> register(String email, String password, String name, String role) async {
    try {
      // Use real API
      final response = await _remoteDataSource.register(email, password, name, role);
      
      // Tokens are already saved in RemoteDataSource.register()
      // Get user data from response
      final userData = response['user'] as Map<String, dynamic>;
      
      // Save user locally
      final userCollection = UserCollection()
        ..serverId = userData['_id'] as String? ?? userData['id'] as String
        ..email = userData['email'] as String
        ..role = userData['role'] as String
        ..name = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim()
        ..lastSync = DateTime.now();
      
      await _localDataSource.saveUser(userCollection);
      
      return UserMapper.toEntity(userCollection);
    } catch (e) {
      // Re-throw with better error message
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
    await _storage.delete(key: AppConstants.userRoleKey);
  }
  
  @override
  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) return null;
    
    try {
      // Try to get from API first
      final userData = await _remoteDataSource.getCurrentUser();
      
      // Save/update user locally
      final userCollection = UserCollection()
        ..serverId = userData['_id'] as String? ?? userData['id'] as String
        ..email = userData['email'] as String
        ..role = userData['role'] as String
        ..name = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim()
        ..lastSync = DateTime.now();
      
      await _localDataSource.saveUser(userCollection);
      return UserMapper.toEntity(userCollection);
    } catch (e) {
      // If API fails, try to get from local cache
      try {
        final localUsers = await _localDataSource.getUsers();
        if (localUsers.isNotEmpty) {
          return UserMapper.toEntity(localUsers.first);
        }
      } catch (localError) {
        // Local fetch also failed
      }
      // Error fetching user - return null
      return null;
    }
  }
  
  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
}
