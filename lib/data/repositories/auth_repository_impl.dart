import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/mock_remote_data_source.dart';
import '../mappers/user_mapper.dart';
import '../models/user_collection.dart' if (dart.library.html) '../models/user_collection_stub.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalDataSource _localDataSource;
  final MockRemoteDataSource _mockRemoteDataSource;
  final FlutterSecureStorage _storage;
  
  AuthRepositoryImpl(this._localDataSource, FlutterSecureStorage storage)
      : _storage = storage,
        _mockRemoteDataSource = MockRemoteDataSource(storage);
  
  @override
  Future<User> login(String email, String password) async {
    // Use mock data source - backend not ready
    final response = await _mockRemoteDataSource.login(email, password);
    
    // Save tokens
    await _storage.write(key: AppConstants.accessTokenKey, value: response['accessToken']);
    await _storage.write(key: AppConstants.refreshTokenKey, value: response['refreshToken']);
    
    // Get user data from response
    final userData = response['user'] as Map<String, dynamic>;
    
    // Save user locally
    final userCollection = UserCollection()
      ..serverId = userData['id'] as String
      ..email = userData['email'] as String
      ..role = userData['role'] as String
      ..name = userData['name'] as String
      ..lastSync = DateTime.now();
    
    await _localDataSource.saveUser(userCollection);
    
    return UserMapper.toEntity(userCollection);
  }
  
  @override
  Future<User> register(String email, String password, String name, String role) async {
    // Use mock data source - backend not ready
    final response = await _mockRemoteDataSource.register(email, password, name, role);
    
    // Save tokens
    await _storage.write(key: AppConstants.accessTokenKey, value: response['accessToken']);
    await _storage.write(key: AppConstants.refreshTokenKey, value: response['refreshToken']);
    
    // Get user data from response
    final userData = response['user'] as Map<String, dynamic>;
    
    // Save user locally
    final userCollection = UserCollection()
      ..serverId = userData['id'] as String
      ..email = userData['email'] as String
      ..role = userData['role'] as String
      ..name = userData['name'] as String
      ..lastSync = DateTime.now();
    
    await _localDataSource.saveUser(userCollection);
    
    return UserMapper.toEntity(userCollection);
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
      // Try to get from local first
      final localUser = await _localDataSource.getUserByServerId('mock_user_123');
      if (localUser != null) {
        return UserMapper.toEntity(localUser);
      }
      
      // If not in local, get from mock
      final userData = await _mockRemoteDataSource.getCurrentUser();
      final userCollection = UserCollection()
        ..serverId = userData['id'] as String
        ..email = userData['email'] as String
        ..role = userData['role'] as String
        ..name = userData['name'] as String
        ..lastSync = DateTime.now();
      
      await _localDataSource.saveUser(userCollection);
      return UserMapper.toEntity(userCollection);
    } catch (e) {
      // Error fetching user
      return null;
    }
  }
  
  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
}

