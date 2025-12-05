import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

/// Mock RemoteDataSource za testiranje bez backend-a
class MockRemoteDataSource {
  final FlutterSecureStorage _storage;
  final Random _random = Random();
  
  MockRemoteDataSource(this._storage);
  
  // Mock login - vraća fake user podatke
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simuliraj network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Generiši fake token
    final fakeToken = base64Encode(utf8.encode('mock_token_${DateTime.now().millisecondsSinceEpoch}'));
    
    // Sačuvaj token
    await _storage.write(key: 'access_token', value: fakeToken);
    await _storage.write(key: 'refresh_token', value: fakeToken);
    
    // Vrati mock user podatke
    return {
      'accessToken': fakeToken,
      'refreshToken': fakeToken,
      'user': {
        'id': 'mock_user_${_random.nextInt(10000)}',
        'email': email,
        'name': email.split('@')[0],
        'role': 'CLIENT',
      }
    };
  }
  
  Future<Map<String, dynamic>> register(String email, String password, String name, String role) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final fakeToken = base64Encode(utf8.encode('mock_token_${DateTime.now().millisecondsSinceEpoch}'));
    
    await _storage.write(key: 'access_token', value: fakeToken);
    await _storage.write(key: 'refresh_token', value: fakeToken);
    
    return {
      'accessToken': fakeToken,
      'refreshToken': fakeToken,
      'user': {
        'id': 'mock_user_${_random.nextInt(10000)}',
        'email': email,
        'name': name,
        'role': role,
      }
    };
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    return {
      'id': 'mock_user_123',
      'email': 'test@example.com',
      'name': 'Test User',
      'role': 'CLIENT',
    };
  }
  
  Future<Map<String, dynamic>> syncBatch(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'processedLogs': data['newLogs']?.length ?? 0,
      'processedCheckIns': data['newCheckIns']?.length ?? 0,
      'errors': [],
    };
  }
  
  Future<Map<String, dynamic>> getSyncChanges(String since) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'workouts': [],
      'checkIns': [],
    };
  }
  
  Future<Map<String, dynamic>> getUploadSignature() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'signature': 'mock_signature',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'cloudName': 'mock_cloud',
      'apiKey': 'mock_key',
      'uploadPreset': 'mock_preset',
      'folder': 'checkins/mock',
    };
  }
}

