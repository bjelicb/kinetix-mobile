import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;
  
  RemoteDataSource(this._dio, this._storage) {
    // Configure Dio
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = ApiConstants.connectTimeout;
    _dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    
    // Add retry interceptor for network errors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers[ApiConstants.authorizationHeader] =
              '${ApiConstants.bearerPrefix}$token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Retry logic for network errors
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
          if (retryCount < 3) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            await Future.delayed(Duration(seconds: retryCount + 1));
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // Retry failed, continue with error
            }
          }
        }
        
        // Handle 401 Unauthorized - try refresh token
        if (error.response?.statusCode == 401) {
          if (!_isRefreshing) {
            _isRefreshing = true;
            final refreshed = await _refreshToken();
            _isRefreshing = false;
            
            if (refreshed) {
              final token = await _storage.read(key: AppConstants.accessTokenKey);
              error.requestOptions.headers[ApiConstants.authorizationHeader] =
                  '${ApiConstants.bearerPrefix}$token';
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                // Retry failed
              }
            }
          }
        }
        
        handler.next(error);
      },
    ));
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
        if (data['refreshToken'] != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        }
        return true;
      }
    } catch (e) {
      // Refresh failed - user needs to login again
    }
    return false;
  }
  
  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        // Save tokens
        await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        return data;
      }
      throw Exception(response.data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error during login');
    }
  }
  
  Future<Map<String, dynamic>> register(String email, String password, String name, String role) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'firstName': name.split(' ').first,
          'lastName': name.split(' ').length > 1 ? name.split(' ').skip(1).join(' ') : '',
          'role': role,
        },
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        // Save tokens
        await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        return data;
      }
      throw Exception(response.data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error during registration');
    }
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      
      if (response.data['success'] == true) {
        return response.data['data']['user'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get user');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      }
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  // Workout Methods
  Future<Map<String, dynamic>> getTodayWorkout() async {
    try {
      final response = await _dio.get(ApiConstants.workoutsToday);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get today workout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<Map<String, dynamic>> getWeekWorkouts(String date) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.workoutsWeek}/$date',
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get week workouts');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    try {
      final response = await _dio.get(ApiConstants.workoutsHistory);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get workout history');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<Map<String, dynamic>> logWorkout(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiConstants.workoutsLog,
        data: data,
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to log workout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<Map<String, dynamic>> updateWorkoutLog(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.workoutsLog}/$id',
        data: data,
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to update workout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<Map<String, dynamic>> getCurrentPlan() async {
    try {
      final response = await _dio.get(ApiConstants.clientsCurrentPlan);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get current plan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  // Check-in Methods
  Future<Map<String, dynamic>> createCheckIn(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkIns,
        data: data,
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to create check-in');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<List<Map<String, dynamic>>> getCheckIns() async {
    try {
      final response = await _dio.get(ApiConstants.checkIns);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get check-ins');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<void> deleteCheckIn(String id) async {
    try {
      final response = await _dio.delete('${ApiConstants.checkIns}/$id');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete check-in');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<List<Map<String, dynamic>>> getPendingCheckIns() async {
    try {
      final response = await _dio.get('${ApiConstants.checkIns}/pending');
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get pending check-ins');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  Future<Map<String, dynamic>> verifyCheckIn(String id, String status, String? reason) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.checkIns}/$id/verify',
        data: {
          'verificationStatus': status,
          if (reason != null) 'rejectionReason': reason,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to verify check-in');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  // Sync Methods
  Future<Map<String, dynamic>> syncBatch(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiConstants.sync,
        data: data,
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Sync failed');
    } on DioException catch (e) {
      // Handle 409 Conflict - Server Wins policy
      if (e.response?.statusCode == 409) {
        // Return server data to overwrite local
        return e.response?.data['data'] ?? {};
      }
      throw Exception(e.response?.data['message'] ?? 'Network error during sync');
    }
  }
  
  Future<Map<String, dynamic>> getSyncChanges(String since) async {
    try {
      final response = await _dio.get(
        ApiConstants.syncChanges,
        queryParameters: {'since': since},
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get sync changes');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  // Media Methods
  Future<Map<String, dynamic>> getUploadSignature() async {
    try {
      final response = await _dio.get(ApiConstants.mediaSignature);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get upload signature');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  // Gamification Methods
  Future<Map<String, dynamic>> getGamificationStatus() async {
    try {
      final response = await _dio.get(ApiConstants.gamificationStatus);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get gamification status');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
  
  // Trainer Methods
  Future<Map<String, dynamic>> getTrainerClients() async {
    try {
      final response = await _dio.get(ApiConstants.trainersClients);
      
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Failed to get trainer clients');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}
