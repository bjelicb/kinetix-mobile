import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'remote_data_source.g.dart';

class RemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;
  late final Dio _refreshDio; // Separate Dio instance for refresh calls to avoid interceptor loops

  /// Helper method to extract data from TransformInterceptor wrapper
  /// Backend wraps all responses in { success: true, data: ... }
  /// Returns the unwrapped data, or null if response format is invalid
  Map<String, dynamic>? _unwrapResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['success'] == true && responseData['data'] != null) {
        return responseData['data'] as Map<String, dynamic>;
      }
      // Fallback: return as-is if no wrapper (for backward compatibility)
      return responseData;
    }
    return null;
  }

  RemoteDataSource(this._dio, this._storage) {
    // Configure Dio
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = ApiConstants.connectTimeout;
    _dio.options.receiveTimeout = ApiConstants.receiveTimeout;

    // Create separate Dio instance for refresh token calls (no interceptors to avoid loops)
    _refreshDio = Dio();
    _refreshDio.options.baseUrl = ApiConstants.baseUrl;
    _refreshDio.options.connectTimeout = ApiConstants.connectTimeout;
    _refreshDio.options.receiveTimeout = ApiConstants.receiveTimeout;

    // Add retry interceptor for network errors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          // Reduced logging - only log warnings
          if (token == null && !options.path.contains('/auth/')) {
            developer.log('[RemoteDataSource] WARNING: No token for ${options.path}', name: 'RemoteDataSource');
          }
          if (token != null) {
            options.headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
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
            // Skip refresh if this is already a refresh token request (shouldn't happen with _refreshDio, but safety check)
            if (error.requestOptions.path.contains('/auth/refresh')) {
              handler.next(error);
              return;
            }

            if (!_isRefreshing) {
              _isRefreshing = true;
              final refreshed = await _refreshToken();
              _isRefreshing = false;

              if (refreshed) {
                final token = await _storage.read(key: AppConstants.accessTokenKey);
                if (token != null) {
                  error.requestOptions.headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
                  try {
                    final response = await _dio.fetch(error.requestOptions);
                    handler.resolve(response);
                    return;
                  } catch (e) {
                    // If retry fails, pass the error through
                  }
                }
              } else {
                // Clear tokens if refresh failed
                await _storage.delete(key: AppConstants.accessTokenKey);
                await _storage.delete(key: AppConstants.refreshTokenKey);
              }
            } else {
              // Wait a bit and retry if refresh is in progress
              await Future.delayed(const Duration(milliseconds: 500));
              final token = await _storage.read(key: AppConstants.accessTokenKey);
              if (token != null) {
                error.requestOptions.headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
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
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }

      // Use separate Dio instance to avoid interceptor loops
      final response = await _refreshDio.post(ApiConstants.refresh, data: {'refreshToken': refreshToken});

      if (response.statusCode == 200) {
        // Handle nested response structure from TransformInterceptor
        // Response format: {success: true, data: {accessToken, refreshToken}, timestamp: ...}
        final responseData = response.data;
        Map<String, dynamic> tokenData;

        if (responseData['success'] == true && responseData['data'] != null) {
          tokenData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Fallback: assume direct structure
          tokenData = responseData as Map<String, dynamic>;
        }

        final accessToken = tokenData['accessToken'];
        final newRefreshToken = tokenData['refreshToken'];

        if (accessToken != null) {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);

          if (newRefreshToken != null) {
            await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);
          }
          return true;
        }
        return false;
      }
    } catch (e) {
      // If refresh token is expired/invalid, clear tokens
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.delete(key: AppConstants.accessTokenKey);
        await _storage.delete(key: AppConstants.refreshTokenKey);
      }
    }
    return false;
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {'email': email, 'password': password});

      if (response.data['success'] == true) {
        final data = response.data['data'];
        // Save tokens
        await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        return data;
      }
      throw Exception(response.data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error during login: ${e.message}');
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
        // Backend returns {id, email, role} directly in data, not nested in 'user'
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          // If data contains 'user', use it, otherwise use data directly
          if (data.containsKey('user')) {
            return data['user'] as Map<String, dynamic>;
          }
          // Backend returns {id, email, role} directly
          return data;
        }
        throw Exception('Invalid response format');
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

  Future<dynamic> getWeekWorkouts(String date) async {
    try {
      final response = await _dio.get('${ApiConstants.workoutsWeek}/$date');

      // Handle both cases: wrapped response or direct array
      if (response.data is List) {
        // Direct array response (if interceptor doesn't wrap)
        return {'data': response.data};
      } else if (response.data is Map && response.data['success'] == true) {
        // Wrapped response: {success: true, data: [...]}
        return response.data['data'];
      } else if (response.data is Map && response.data.containsKey('data')) {
        // Response has data field but no success field
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

  /// Get ALL workout logs (completed, pending, missed) for the client
  /// This replaces getWeekWorkouts() to load all workout logs from all plans
  Future<dynamic> getAllWorkoutLogs() async {
    try {
      final response = await _dio.get(ApiConstants.workoutsAllLogs);

      // Handle both cases: wrapped response or direct array
      if (response.data is List) {
        // Direct array response (if interceptor doesn't wrap)
        return {'data': response.data};
      } else if (response.data is Map && response.data['success'] == true) {
        // Wrapped response: {success: true, data: [...]}
        return response.data['data'];
      } else if (response.data is Map && response.data.containsKey('data')) {
        // Response has data field but no success field
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get all workout logs');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> logWorkout(Map<String, dynamic> data) async {
    try {
      developer.log('[RemoteDataSource:LogWorkout] ═══════════════════════════════════════', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Calling POST ${ApiConstants.workoutsLog}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Request data: $data', name: 'RemoteDataSource');
      
      final response = await _dio.post(ApiConstants.workoutsLog, data: data);
      
      developer.log('[RemoteDataSource:LogWorkout] Response status: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        developer.log('[RemoteDataSource:LogWorkout] ✅ Success - returning data', name: 'RemoteDataSource');
        developer.log('[RemoteDataSource:LogWorkout] ═══════════════════════════════════════', name: 'RemoteDataSource');
        return response.data['data'];
      }
      
      final errorMessage = response.data['message'] ?? 'Failed to log workout';
      developer.log('[RemoteDataSource:LogWorkout] ❌ Backend error: $errorMessage', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] ═══════════════════════════════════════', name: 'RemoteDataSource');
      throw Exception(errorMessage);
    } on DioException catch (e) {
      developer.log('[RemoteDataSource:LogWorkout] ❌ DioException caught', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Exception type: ${e.type}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Exception message: ${e.message}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Response status: ${e.response?.statusCode}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] Response data: ${e.response?.data}', name: 'RemoteDataSource');
      
      // Check if it's a real network error or backend validation error
      final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response == null; // No response = network error
      
      if (isNetworkError) {
        developer.log('[RemoteDataSource:LogWorkout] → Real network error detected', name: 'RemoteDataSource');
        developer.log('[RemoteDataSource:LogWorkout] ═══════════════════════════════════════', name: 'RemoteDataSource');
        throw Exception('Network error: ${e.message}');
      } else {
        // Backend returned an error response (400, 401, 500, etc.)
        final errorMessage = e.response?.data['message'] ?? 'Backend error: ${e.response?.statusCode}';
        developer.log('[RemoteDataSource:LogWorkout] → Backend validation/error: $errorMessage', name: 'RemoteDataSource');
        developer.log('[RemoteDataSource:LogWorkout] ═══════════════════════════════════════', name: 'RemoteDataSource');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('[RemoteDataSource:LogWorkout] ❌ Unexpected error: $e', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource:LogWorkout] ═══════════════════════════════════════', name: 'RemoteDataSource');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateWorkoutLog(String id, Map<String, dynamic> data) async {
    // ✅ Backend endpoint is @Patch(':id') on @Controller('workouts'), so it's /workouts/:id
    final endpoint = '/workouts/$id';
    developer.log('updateWorkoutLog() calling $endpoint', name: 'RemoteDataSource:UpdateWorkoutLog');
    developer.log('updateWorkoutLog() data: $data', name: 'RemoteDataSource:UpdateWorkoutLog');
    try {
      // ✅ Use PATCH instead of PUT to match backend @Patch(':id') endpoint
      final response = await _dio.patch(endpoint, data: data);
      developer.log('updateWorkoutLog() response status: ${response.statusCode}', name: 'RemoteDataSource:UpdateWorkoutLog');
      developer.log('updateWorkoutLog() response data: ${response.data}', name: 'RemoteDataSource:UpdateWorkoutLog');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      developer.log('updateWorkoutLog() error: ${e.message}', name: 'RemoteDataSource:UpdateWorkoutLog');
      developer.log('updateWorkoutLog() error response: ${e.response?.data}', name: 'RemoteDataSource:UpdateWorkoutLog');
      throw Exception(e.response?.data['message'] ?? 'Failed to update workout log');
    }
  }

  Future<Map<String, dynamic>> getCurrentPlan() async {
    developer.log('═══════════════════════════════════════════════════════════', name: 'RemoteDataSource');
    developer.log('[RemoteDataSource] getCurrentPlan() START', name: 'RemoteDataSource');
    developer.log('[RemoteDataSource] → Base URL: ${_dio.options.baseUrl}', name: 'RemoteDataSource');
    developer.log('[RemoteDataSource] → API endpoint: ${ApiConstants.clientsCurrentPlan}', name: 'RemoteDataSource');
    developer.log(
      '[RemoteDataSource] → Full URL: ${_dio.options.baseUrl}${ApiConstants.clientsCurrentPlan}',
      name: 'RemoteDataSource',
    );

    // Check if token exists
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    developer.log('[RemoteDataSource] → Token exists: ${token != null}', name: 'RemoteDataSource');
    if (token != null) {
      developer.log(
        '[RemoteDataSource] → Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        name: 'RemoteDataSource',
      );
    }

    try {
      developer.log('[RemoteDataSource] → Sending GET request to backend...', name: 'RemoteDataSource');
      final response = await _dio.get(ApiConstants.clientsCurrentPlan);

      developer.log('[RemoteDataSource] → Response status: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Response data type: ${response.data.runtimeType}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        developer.log('[RemoteDataSource] → Success: true', name: 'RemoteDataSource');
        developer.log('[RemoteDataSource] → Data type: ${data.runtimeType}', name: 'RemoteDataSource');

        if (data == null) {
          developer.log('[RemoteDataSource] ✗ Data is null - no active plan', name: 'RemoteDataSource');
          return <String, dynamic>{};
        }

        if (data is Map) {
          developer.log('[RemoteDataSource] → Data keys: ${data.keys.toList()}', name: 'RemoteDataSource');
          developer.log('[RemoteDataSource] ✓ Plan data received', name: 'RemoteDataSource');
          return Map<String, dynamic>.from(data);
        } else {
          developer.log('[RemoteDataSource] ✗ Data is not a Map: ${data.runtimeType}', name: 'RemoteDataSource');
          return <String, dynamic>{};
        }
      } else {
        final message = response.data['message'] ?? 'Failed to get current plan';
        developer.log('[RemoteDataSource] ✗ Success: false - $message', name: 'RemoteDataSource');
        throw Exception(message);
      }
    } on DioException catch (e) {
      developer.log('[RemoteDataSource] ✗✗✗ DioException occurred!', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Exception type: ${e.type}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Exception message: ${e.message}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Status code: ${e.response?.statusCode}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Response data: ${e.response?.data}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Request path: ${e.requestOptions.path}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Request baseUrl: ${e.requestOptions.baseUrl}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Request headers: ${e.requestOptions.headers}', name: 'RemoteDataSource');

      // Handle different DioException types
      String errorMessage = 'Network error';
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'] as String;
        } else {
          errorMessage = 'HTTP ${e.response!.statusCode}: ${errorData.toString()}';
        }
      } else {
        // No response - likely network/CORS issue
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'Connection timeout - check if backend is running';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = 'Send timeout';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Receive timeout';
            break;
          case DioExceptionType.badResponse:
            errorMessage = 'Bad response: ${e.response?.statusCode}';
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Request cancelled';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Connection error - check CORS settings or backend URL';
            break;
          default:
            errorMessage = 'Network error: ${e.message}';
        }
      }

      developer.log('[RemoteDataSource] → Final error message: $errorMessage', name: 'RemoteDataSource');
      developer.log('═══════════════════════════════════════════════════════════', name: 'RemoteDataSource');
      throw Exception(errorMessage);
    } catch (e) {
      developer.log('[RemoteDataSource] ✗✗✗ Unexpected error: $e', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Error type: ${e.runtimeType}', name: 'RemoteDataSource');
      throw Exception('Unexpected error: $e');
    }
  }

  // Check-in Methods
  Future<Map<String, dynamic>> createCheckIn(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.checkIns, data: data);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to create check-in');
    } on DioException catch (e) {
      debugPrint('[RemoteDataSource] ❌ Error creating check-in: ${e.response?.statusCode}');
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
        data: {'verificationStatus': status, if (reason != null) 'rejectionReason': reason},
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
      final response = await _dio.post(ApiConstants.sync, data: data);

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
      final response = await _dio.get(ApiConstants.syncChanges, queryParameters: {'since': since});

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

  Future<Map<String, dynamic>> getBalance() async {
    try {
      developer.log('getBalance() calling ${ApiConstants.gamificationBalance}', name: 'RemoteDataSource');
      final response = await _dio.get(ApiConstants.gamificationBalance);
      developer.log('getBalance() response status: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('getBalance() response data: ${response.data}', name: 'RemoteDataSource');

      // TransformInterceptor wraps all responses in { success: true, data: ... }
      if (response.data is Map && response.data['success'] == true && response.data['data'] != null) {
        developer.log('getBalance() response is wrapped, extracting data', name: 'RemoteDataSource');
        final data = response.data['data'];
        developer.log('getBalance() extracted data: $data', name: 'RemoteDataSource');
        return data;
      }

      // Fallback: if not wrapped, return directly (shouldn't happen with TransformInterceptor)
      developer.log('getBalance() WARNING: response not wrapped, returning directly', name: 'RemoteDataSource');
      return response.data;
    } on DioException catch (e) {
      developer.log('getBalance() error: ${e.message}', name: 'RemoteDataSource');
      developer.log('getBalance() error response: ${e.response?.data}', name: 'RemoteDataSource');
      throw Exception(e.response?.data['message'] ?? 'Failed to get balance');
    }
  }

  Future<void> clearBalance() async {
    try {
      developer.log('clearBalance() calling ${ApiConstants.gamificationClearBalance}', name: 'RemoteDataSource:ClearBalance');
      final response = await _dio.post(ApiConstants.gamificationClearBalance);
      developer.log('clearBalance() response status: ${response.statusCode}', name: 'RemoteDataSource:ClearBalance');
      developer.log('clearBalance() response data: ${response.data}', name: 'RemoteDataSource:ClearBalance');
    } on DioException catch (e) {
      developer.log('clearBalance() error: ${e.message}', name: 'RemoteDataSource:ClearBalance');
      developer.log('clearBalance() error response: ${e.response?.data}', name: 'RemoteDataSource:ClearBalance');
      throw Exception(e.response?.data['message'] ?? 'Failed to clear balance');
    }
  }

  // Weigh-in Methods
  Future<Map<String, dynamic>> createWeighIn({
    required double weight,
    DateTime? date,
    String? photoUrl,
    String? notes,
    String? planId,
  }) async {
    try {
      final data = <String, dynamic>{
        'weight': weight,
        'date': date?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (notes != null) data['notes'] = notes;
      if (planId != null) data['planId'] = planId;

      final response = await _dio.post('/checkins/weigh-in', data: data);

      // Handle TransformInterceptor wrapper
      if (response.data is Map && response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create weigh-in');
    }
  }

  Future<List<Map<String, dynamic>>> getWeighInHistory() async {
    try {
      final response = await _dio.get('/checkins/weigh-in/history');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get weigh-in history');
    }
  }

  Future<Map<String, dynamic>?> getLatestWeighIn() async {
    try {
      developer.log('getLatestWeighIn() calling /checkins/weigh-in/latest', name: 'RemoteDataSource');
      final response = await _dio.get('/checkins/weigh-in/latest');
      developer.log('getLatestWeighIn() response status: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('getLatestWeighIn() response data: ${response.data}', name: 'RemoteDataSource');

      // TransformInterceptor wraps all responses in { success: true, data: ... }
      // But this endpoint might return null if no weigh-in exists (404)
      if (response.statusCode == 404) {
        developer.log('getLatestWeighIn() - No weigh-in found (404)', name: 'RemoteDataSource');
        return null;
      }

      // TransformInterceptor wraps all responses in { success: true, data: ... }
      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          developer.log('getLatestWeighIn() - No weigh-in data (data is null)', name: 'RemoteDataSource');
          return null;
        }
        developer.log('getLatestWeighIn() response is wrapped, extracting data', name: 'RemoteDataSource');
        developer.log('getLatestWeighIn() extracted data: $data', name: 'RemoteDataSource');
        return data as Map<String, dynamic>?;
      }

      // If data is null (no weigh-in), return null
      if (response.data == null) {
        developer.log('getLatestWeighIn() - No weigh-in data (response.data is null)', name: 'RemoteDataSource');
        return null;
      }

      // Fallback: return directly if not wrapped
      developer.log('getLatestWeighIn() returning response.data directly', name: 'RemoteDataSource');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        developer.log('getLatestWeighIn() - 404 Not Found (no weigh-in exists)', name: 'RemoteDataSource');
        return null; // No weigh-in is not an error
      }
      developer.log('getLatestWeighIn() error: ${e.message}', name: 'RemoteDataSource');
      developer.log('getLatestWeighIn() error response: ${e.response?.data}', name: 'RemoteDataSource');
      throw Exception(e.response?.data['message'] ?? 'Failed to get latest weigh-in');
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

  // Admin Methods
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      developer.log('Calling GET ${ApiConstants.adminUsers}', name: 'RemoteDataSource');
      final response = await _dio.get(ApiConstants.adminUsers);
      developer.log('Response status: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('Response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        // Backend returns nested structure: {success: true, data: {success: true, data: [...]}}
        if (outerData is Map && outerData['success'] == true) {
          final innerData = outerData['data'];
          if (innerData is List) {
            developer.log('Returning ${innerData.length} users', name: 'RemoteDataSource');
            return List<Map<String, dynamic>>.from(innerData);
          }
        }
        // Fallback: check if data is directly a list
        if (outerData is List) {
          developer.log('Returning ${outerData.length} users (direct list)', name: 'RemoteDataSource');
          return List<Map<String, dynamic>>.from(outerData);
        }
        developer.log('Data structure not recognized, returning empty', name: 'RemoteDataSource');
        return [];
      }
      throw Exception(response.data['message'] ?? 'Failed to get users');
    } on DioException catch (e) {
      developer.log('DioException: ${e.message}', name: 'RemoteDataSource', error: e);
      developer.log('Response: ${e.response?.data}', name: 'RemoteDataSource');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      // Use existing register endpoint
      final response = await _dio.post(
        ApiConstants.register,
        data: {'email': email, 'password': password, 'firstName': firstName, 'lastName': lastName, 'role': role},
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to create user');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _dio.get(ApiConstants.adminStats);

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        // Handle potential nested structure like getAllUsers
        if (outerData is Map && outerData['success'] == true && outerData['data'] != null) {
          return outerData['data'] as Map<String, dynamic>;
        }
        return outerData as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to get admin stats');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> assignClientToTrainer({
    required String clientId,
    String? trainerId, // Optional: null means unassign
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminAssignClient,
        data: {
          'clientId': clientId,
          'trainerId': trainerId, // Send null explicitly for unassign
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to assign client');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.response?.data?['error']?['message'] ?? 'Network error';
      throw Exception(errorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> getAllPlans() async {
    try {
      final response = await _dio.get(ApiConstants.adminPlans);

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        // Handle nested structure like getAllUsers
        if (outerData is Map && outerData['success'] == true && outerData['data'] != null) {
          final innerData = outerData['data'];
          if (innerData is List) {
            return List<Map<String, dynamic>>.from(innerData);
          }
        }
        // Fallback: check if data is directly a list
        if (outerData is List) {
          return List<Map<String, dynamic>>.from(outerData);
        }
        return [];
      }
      throw Exception(response.data['message'] ?? 'Failed to get plans');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    try {
      developer.log(
        '[RemoteDataSource] getAllWorkouts START - calling API: ${ApiConstants.adminWorkoutsAll}',
        name: 'RemoteDataSource',
      );
      final response = await _dio.get(ApiConstants.adminWorkoutsAll);

      developer.log(
        '[RemoteDataSource] getAllWorkouts - response status: ${response.statusCode}',
        name: 'RemoteDataSource',
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        developer.log('[RemoteDataSource] getAllWorkouts - data type: ${data.runtimeType}', name: 'RemoteDataSource');

        if (data is List) {
          final workouts = List<Map<String, dynamic>>.from(data);
          developer.log(
            '[RemoteDataSource] getAllWorkouts SUCCESS - returning ${workouts.length} workouts',
            name: 'RemoteDataSource',
          );

          if (workouts.isNotEmpty) {
            final sampleWorkout = workouts.first;
            developer.log(
              '[RemoteDataSource] getAllWorkouts - sample workout: id=${sampleWorkout['_id']}, clientId=${sampleWorkout['clientId']}, date=${sampleWorkout['workoutDate']}',
              name: 'RemoteDataSource',
            );
          }

          return workouts;
        }
        developer.log(
          '[RemoteDataSource] getAllWorkouts WARNING - data is not a List, returning empty list',
          name: 'RemoteDataSource',
        );
        return [];
      }
      developer.log(
        '[RemoteDataSource] getAllWorkouts ERROR - API returned success=false: ${response.data['message']}',
        name: 'RemoteDataSource',
      );
      throw Exception(response.data['message'] ?? 'Failed to get workouts');
    } on DioException catch (e) {
      developer.log(
        '[RemoteDataSource] getAllWorkouts ERROR - DioException: ${e.message}',
        name: 'RemoteDataSource',
        error: e,
      );
      developer.log(
        '[RemoteDataSource] getAllWorkouts ERROR - response data: ${e.response?.data}',
        name: 'RemoteDataSource',
      );
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      final response = await _dio.get(ApiConstants.adminWorkoutsStats);

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        if (outerData is Map && outerData['success'] == true && outerData['data'] != null) {
          return outerData['data'] as Map<String, dynamic>;
        }
        return outerData as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to get workout stats');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (email != null) data['email'] = email;
      if (role != null) data['role'] = role;

      final response = await _dio.patch(ApiConstants.adminUpdateUser(userId), data: data);

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        // Handle nested structure like other endpoints
        if (outerData is Map && outerData['success'] == true && outerData['data'] != null) {
          return outerData['data'] as Map<String, dynamic>;
        }
        return outerData as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to update user');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      developer.log('[RemoteDataSource] deleteUser called with ID: $userId');
      final url = ApiConstants.adminDeleteUser(userId);
      developer.log('[RemoteDataSource] DELETE URL: $url');

      final response = await _dio.delete(url);
      developer.log('[RemoteDataSource] Delete response status: ${response.statusCode}');
      developer.log('[RemoteDataSource] Delete response data: ${response.data}');
      developer.log('[RemoteDataSource] Delete response data type: ${response.data.runtimeType}');

      // Handle different response formats
      final responseData = response.data;
      bool success = false;
      String? message;

      if (responseData is Map) {
        // Check if response is wrapped in 'data' field (NestJS standard format)
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final data = responseData['data'] as Map;
          success = data['success'] == true;
          message = data['message'] as String?;
        } else {
          // Direct response format
          success = responseData['success'] == true;
          message = responseData['message'] as String?;
        }
      }

      developer.log('[RemoteDataSource] Parsed success: $success, message: $message');

      if (!success) {
        final errorMsg = message ?? 'Failed to delete user';
        developer.log('[RemoteDataSource] Delete failed: $errorMsg');
        throw Exception(errorMsg);
      }
      developer.log('[RemoteDataSource] Delete successful');
    } on DioException catch (e) {
      developer.log('[RemoteDataSource] DioException: ${e.message}');
      developer.log('[RemoteDataSource] Response: ${e.response?.data}');
      developer.log('[RemoteDataSource] Status code: ${e.response?.statusCode}');
      throw Exception(e.response?.data['message'] ?? 'Network error: ${e.message}');
    } catch (e, stackTrace) {
      developer.log('[RemoteDataSource] Unexpected error: $e');
      developer.log('[RemoteDataSource] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateUserStatus({required String userId, required bool isActive}) async {
    try {
      final response = await _dio.patch(ApiConstants.adminUpdateUserStatus(userId), data: {'isActive': isActive});

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update user status');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  // Plan Management Methods
  Future<Map<String, dynamic>> getPlanById(String planId) async {
    developer.log('═══════════════════════════════════════════════════════════', name: 'RemoteDataSource');
    developer.log('[RemoteDataSource] getPlanById() START', name: 'RemoteDataSource');
    developer.log('[RemoteDataSource] → Plan ID: $planId', name: 'RemoteDataSource');
    developer.log('[RemoteDataSource] → API endpoint: ${ApiConstants.planById(planId)}', name: 'RemoteDataSource');
    developer.log(
      '[RemoteDataSource] → Full URL: ${_dio.options.baseUrl}${ApiConstants.planById(planId)}',
      name: 'RemoteDataSource',
    );

    try {
      final response = await _dio.get(ApiConstants.planById(planId));

      developer.log('[RemoteDataSource] → Response status: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        if (outerData is Map && outerData['success'] == true && outerData['data'] != null) {
          developer.log('[RemoteDataSource] ✓ Plan data received (nested format)', name: 'RemoteDataSource');
          developer.log('═══════════════════════════════════════════════════════════', name: 'RemoteDataSource');
          return outerData['data'] as Map<String, dynamic>;
        }
        developer.log('[RemoteDataSource] ✓ Plan data received (direct format)', name: 'RemoteDataSource');
        developer.log('═══════════════════════════════════════════════════════════', name: 'RemoteDataSource');
        return outerData as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to get plan');
    } on DioException catch (e) {
      developer.log('[RemoteDataSource] ✗✗✗ DioException in getPlanById!', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Exception type: ${e.type}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Status code: ${e.response?.statusCode}', name: 'RemoteDataSource');
      developer.log('[RemoteDataSource] → Response data: ${e.response?.data}', name: 'RemoteDataSource');

      // Check if it's a 403 Forbidden (role-based access)
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        developer.log(
          '[RemoteDataSource] → Access denied - may need CLIENT-specific endpoint',
          name: 'RemoteDataSource',
        );
      }

      developer.log('═══════════════════════════════════════════════════════════', name: 'RemoteDataSource');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData) async {
    try {
      final response = await _dio.post(ApiConstants.plans, data: planData);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Invalid response format from server');
      }
      throw Exception(response.data['message'] ?? 'Failed to create plan');
    } on DioException catch (e) {
      // Provide more detailed error information
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final message = errorData['message'] ?? errorData['error'] ?? 'Failed to create plan';
          throw Exception(message);
        }
        throw Exception('Server error: ${e.response?.statusCode}');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updatePlan(String planId, Map<String, dynamic> planData) async {
    try {
      developer.log('updatePlan - planId: $planId, planData: $planData', name: 'RemoteDataSource');
      final response = await _dio.patch(ApiConstants.planUpdate(planId), data: planData);

      developer.log('updatePlan response: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        final planData = response.data['data'];
        // Handle both cases: direct data or nested data structure
        if (planData is Map) {
          // Check if it's a double-wrapped response
          if (planData['success'] == true && planData['data'] != null) {
            return planData['data'] as Map<String, dynamic>;
          }
          return planData as Map<String, dynamic>;
        }
        throw Exception('Invalid response format: expected Map but got ${planData.runtimeType}');
      }
      throw Exception(response.data['message'] ?? 'Failed to update plan');
    } on DioException catch (e) {
      developer.log('updatePlan error: ${e.response?.data}', name: 'RemoteDataSource');
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Network error');
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      developer.log('deletePlan - planId: $planId', name: 'RemoteDataSource');
      final response = await _dio.delete(ApiConstants.planDelete(planId));

      developer.log('deletePlan response: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('deletePlan response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Failed to delete plan');
    } on DioException catch (e) {
      developer.log('deletePlan error: ${e.message}', name: 'RemoteDataSource', error: e);
      developer.log('deletePlan error response: ${e.response?.data}', name: 'RemoteDataSource');
      developer.log('deletePlan error status: ${e.response?.statusCode}', name: 'RemoteDataSource');
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final message = errorData['message'] ?? errorData['error'] ?? 'Failed to delete plan';
          throw Exception(message);
        }
        throw Exception('Server error: ${e.response?.statusCode}');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Formats DateTime to YYYY-MM-DD string for backend (parsed as UTC)
  String _formatDateAsUtcString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> assignPlanToClients(String planId, List<String> clientIds, DateTime startDate) async {
    try {
      final dateString = _formatDateAsUtcString(startDate);

      final response = await _dio.post(
        ApiConstants.planAssign(planId),
        data: {'clientIds': clientIds, 'startDate': dateString},
      );

      if (response.data['success'] == true) {
        final outerData = response.data['data'];
        if (outerData is Map && outerData['success'] == true && outerData['data'] != null) {
          return outerData['data'] as Map<String, dynamic>;
        }
        return outerData as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to assign plan');
    } on DioException catch (e) {
      developer.log('assignPlanToClients error: ${e.message}', name: 'RemoteDataSource', error: e);
      developer.log('assignPlanToClients error response: ${e.response?.data}', name: 'RemoteDataSource');
      developer.log('assignPlanToClients error status: ${e.response?.statusCode}', name: 'RemoteDataSource');
      // Provide more detailed error information
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final message = errorData['message'] ?? errorData['error'] ?? 'Failed to assign plan';
          throw Exception(message);
        }
        throw Exception('Server error: ${e.response?.statusCode}');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> duplicatePlan(String planId) async {
    try {
      developer.log('duplicatePlan - planId: $planId', name: 'RemoteDataSource');
      final response = await _dio.post(ApiConstants.planDuplicate(planId));

      developer.log('duplicatePlan response: ${response.statusCode}', name: 'RemoteDataSource');
      developer.log('duplicatePlan response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Invalid response format from server');
      }
      throw Exception(response.data['message'] ?? 'Failed to duplicate plan');
    } on DioException catch (e) {
      developer.log('duplicatePlan error: ${e.message}', name: 'RemoteDataSource', error: e);
      developer.log('duplicatePlan error response: ${e.response?.data}', name: 'RemoteDataSource');
      developer.log('duplicatePlan error status: ${e.response?.statusCode}', name: 'RemoteDataSource');
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final message = errorData['message'] ?? errorData['error'] ?? 'Failed to duplicate plan';
          throw Exception(message);
        }
        throw Exception('Server error: ${e.response?.statusCode}');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> cancelPlan(String planId, String clientId) async {
    try {
      developer.log(
        '[RemoteDataSource] cancelPlan START - planId: $planId, clientId: $clientId',
        name: 'RemoteDataSource',
      );
      final url = ApiConstants.planCancel(planId, clientId);
      developer.log('[RemoteDataSource] cancelPlan - URL: $url', name: 'RemoteDataSource');

      final response = await _dio.post(url);

      developer.log(
        '[RemoteDataSource] cancelPlan - response status: ${response.statusCode}',
        name: 'RemoteDataSource',
      );
      developer.log('[RemoteDataSource] cancelPlan - response data: ${response.data}', name: 'RemoteDataSource');

      if (response.data['success'] != true) {
        final errorMsg = response.data['message'] ?? 'Failed to cancel plan';
        developer.log('[RemoteDataSource] cancelPlan ERROR - $errorMsg', name: 'RemoteDataSource');
        throw Exception(errorMsg);
      }

      developer.log(
        '[RemoteDataSource] cancelPlan SUCCESS - Plan cancelled for client $clientId',
        name: 'RemoteDataSource',
      );
    } on DioException catch (e) {
      developer.log(
        '[RemoteDataSource] cancelPlan ERROR - DioException: ${e.message}',
        name: 'RemoteDataSource',
        error: e,
      );
      developer.log(
        '[RemoteDataSource] cancelPlan ERROR - response data: ${e.response?.data}',
        name: 'RemoteDataSource',
      );
      developer.log(
        '[RemoteDataSource] cancelPlan ERROR - status code: ${e.response?.statusCode}',
        name: 'RemoteDataSource',
      );
      throw Exception(e.response?.data['message'] ?? 'Network error: ${e.message}');
    } catch (e) {
      developer.log('[RemoteDataSource] cancelPlan ERROR - Unexpected error: $e', name: 'RemoteDataSource', error: e);
      rethrow;
    }
  }

  // Workout Management Methods
  Future<void> updateWorkoutStatus({required String workoutId, bool? isCompleted, bool? isMissed}) async {
    try {
      final data = <String, dynamic>{};
      if (isCompleted != null) data['isCompleted'] = isCompleted;
      if (isMissed != null) data['isMissed'] = isMissed;

      final response = await _dio.patch(ApiConstants.adminUpdateWorkoutStatus(workoutId), data: data);

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update workout status');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      developer.log('[RemoteDataSource] deleteWorkout called with ID: $workoutId');
      final url = ApiConstants.adminDeleteWorkout(workoutId);
      developer.log('[RemoteDataSource] DELETE URL: $url');

      final response = await _dio.delete(url);
      developer.log('[RemoteDataSource] Delete response status: ${response.statusCode}');
      developer.log('[RemoteDataSource] Delete response data: ${response.data}');
      developer.log('[RemoteDataSource] Delete response data type: ${response.data.runtimeType}');

      // Handle different response formats
      final responseData = response.data;
      bool success = false;
      String? message;

      if (responseData is Map) {
        // Check if response is wrapped in 'data' field (NestJS standard format)
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final data = responseData['data'] as Map;
          success = data['success'] == true;
          message = data['message'] as String?;
        } else {
          // Direct response format
          success = responseData['success'] == true;
          message = responseData['message'] as String?;
        }
      }

      developer.log('[RemoteDataSource] Parsed success: $success, message: $message');

      if (!success) {
        final errorMsg = message ?? 'Failed to delete workout';
        developer.log('[RemoteDataSource] Delete failed: $errorMsg');
        throw Exception(errorMsg);
      }
      developer.log('[RemoteDataSource] Delete successful');
    } on DioException catch (e) {
      developer.log('[RemoteDataSource] DioException: ${e.message}');
      developer.log('[RemoteDataSource] Response: ${e.response?.data}');
      developer.log('[RemoteDataSource] Status code: ${e.response?.statusCode}');
      throw Exception(e.response?.data['message'] ?? 'Network error: ${e.message}');
    } catch (e, stackTrace) {
      developer.log('[RemoteDataSource] Unexpected error: $e');
      developer.log('[RemoteDataSource] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ========== CLIENT PROFILE API ==========

  /// Get client profile (returns clientProfileId)
  /// GET /clients/profile
  Future<Map<String, dynamic>> getClientProfile(String userId) async {
    try {
      final response = await _dio.get('/clients/profile');

      // Handle wrapped response format (success + data)
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        
        // If response is wrapped with 'success' and 'data', unwrap it
        if (responseMap.containsKey('success') && responseMap.containsKey('data')) {
          final data = responseMap['data'];
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
        
        // Otherwise return as-is (direct data)
        return responseMap;
      }

      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      debugPrint('[RemoteDataSource] ❌ Error getting client profile: ${e.response?.statusCode}');
      rethrow;
    }
  }

  // ========== AI MESSAGES API ==========

  /// Get AI messages for a client
  /// GET /gamification/messages/:clientId
  Future<List<Map<String, dynamic>>> getAIMessages(String clientId) async {
    try {
      final response = await _dio.get('/gamification/messages/$clientId');

      // Handle different response formats
      if (response.data is List) {
        final messages = List<Map<String, dynamic>>.from(response.data);
        return messages;
      } else if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap['success'] == true && responseMap['data'] is List) {
          final messages = List<Map<String, dynamic>>.from(responseMap['data']);
          return messages;
        } else if (responseMap['data'] is List) {
          final messages = List<Map<String, dynamic>>.from(responseMap['data']);
          return messages;
        }
      }

      return [];
    } on DioException catch (e) {
      debugPrint('[RemoteDataSource] ⚠️ Error loading AI messages: ${e.response?.statusCode}');
      
      // Handle rate limiting (429) - return empty list and let retry happen at higher level
      if (e.response?.statusCode == 429) {
        return [];
      }
      
      // If 404 or empty response, return empty list instead of throwing
      if (e.response?.statusCode == 404 || e.response?.statusCode == 200) {
        return [];
      }
      
      // For other errors, return empty list to prevent breaking the entire list
      return [];
    } catch (e) {
      debugPrint('[RemoteDataSource] ⚠️ Unexpected error loading AI messages: $e');
      return [];
    }
  }

  /// GET /gamification/messages/all (Admin only)
  /// Get all AI messages across all clients
  Future<List<Map<String, dynamic>>> getAllAIMessages() async {
    try {
      final response = await _dio.get('/gamification/messages/all');

      // Handle different response formats
      if (response.data is List) {
        final messages = List<Map<String, dynamic>>.from(response.data);
        return messages;
      } else if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap['success'] == true && responseMap['data'] is List) {
          final messages = List<Map<String, dynamic>>.from(responseMap['data']);
          return messages;
        } else if (responseMap['data'] is List) {
          final messages = List<Map<String, dynamic>>.from(responseMap['data']);
          return messages;
        }
      }

      return [];
    } on DioException catch (e) {
      debugPrint('[RemoteDataSource] ⚠️ Error loading all AI messages: ${e.response?.statusCode}');
      
      // Handle rate limiting (429) - return empty list
      if (e.response?.statusCode == 429) {
        return [];
      }
      
      // For other errors, return empty list to prevent breaking
      return [];
    } catch (e) {
      debugPrint('[RemoteDataSource] ⚠️ Unexpected error loading all AI messages: $e');
      return [];
    }
  }

  /// Mark AI message as read
  /// PATCH /gamification/messages/:messageId/read
  Future<void> markAIMessageAsRead(String messageId) async {
    try {
      developer.log('[RemoteDataSource:AIMessages] Marking message $messageId as read');
      await _dio.patch('/gamification/messages/$messageId/read');
      developer.log('[RemoteDataSource:AIMessages] ✓ Message marked as read');
    } on DioException catch (e) {
      developer.log('[RemoteDataSource:AIMessages] ✗ Error: ${e.message}', error: e);
      throw Exception(e.response?.data['message'] ?? 'Failed to mark message as read');
    }
  }

  /// Generate AI message (template or custom)
  /// POST /gamification/generate-message
  Future<Map<String, dynamic>> generateAIMessage({
    required String clientId,
    required String trigger,
    String? customMessage,
    String? tone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'clientId': clientId,
        'trigger': trigger,
        if (customMessage != null) 'customMessage': customMessage,
        if (tone != null) 'tone': tone,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      };
      
      final response = await _dio.post('/gamification/generate-message', data: requestData);

      // TransformInterceptor wraps response in {success: true, data: ...}
      // But handle both wrapped and unwrapped responses
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap['success'] == true) {
          return responseMap['data'] ?? responseMap;
        }
        // If no 'success' field, assume it's the data directly (shouldn't happen with TransformInterceptor)
        if (responseMap.containsKey('_id') || responseMap.containsKey('message')) {
          return responseMap;
        }
      }
      
      throw Exception(response.data['message'] ?? 'Failed to generate message');
    } on DioException catch (e) {
      debugPrint('[RemoteDataSource] ❌ Error generating AI message: ${e.response?.statusCode}');
      throw Exception(e.response?.data['message'] ?? 'Failed to generate message');
    } catch (e) {
      debugPrint('[RemoteDataSource] ❌ Unexpected error generating AI message: $e');
      throw Exception('Failed to generate message: $e');
    }
  }

  // ========== PLANS API - UNLOCK NEXT WEEK ==========

  /// Check if client can unlock next week
  /// GET /plans/unlock-next-week/:clientId
  Future<bool> canUnlockNextWeek(String clientId) async {
    try {
      final response = await _dio.get('/plans/unlock-next-week/$clientId');

      // Handle TransformInterceptor wrapper: { success: true, data: { canUnlock: true } }
      final unwrappedData = _unwrapResponse(response.data);
      final canUnlock = unwrappedData?['canUnlock'] ?? false;
      
      return canUnlock;
    } on DioException catch (e) {
      debugPrint('[RemoteDataSource] ❌ Error checking unlock status: ${e.response?.statusCode}');
      // Return false on error (fail-safe)
      return false;
    } catch (e, stackTrace) {
      developer.log('[RemoteDataSource:UnlockWeek] ✗ Unexpected error: $e');
      developer.log('[RemoteDataSource:UnlockWeek] Stack trace: $stackTrace');
      developer.log('═══════════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Request next week plan assignment
  /// POST /plans/request-next-week/:clientId
  Future<Map<String, dynamic>?> requestNextWeek(String clientId) async {
    try {
      developer.log('[RemoteDataSource:UnlockWeek] requestNextWeek START - clientId: $clientId');
      developer.log('[RemoteDataSource:UnlockWeek] Request payload: { clientId: $clientId }');
      developer.log('[RemoteDataSource:UnlockWeek] POST /plans/request-next-week/$clientId');
      
      final response = await _dio.post('/plans/request-next-week/$clientId');
      
      developer.log('[RemoteDataSource:UnlockWeek] ✓ Request sent successfully');
      developer.log('[RemoteDataSource:UnlockWeek] Response status: ${response.statusCode}');
      developer.log('[RemoteDataSource:UnlockWeek] Response data: ${response.data}');
      developer.log('[RemoteDataSource:UnlockWeek] Response data type: ${response.data.runtimeType}');
      
      // Use _unwrapResponse() for consistent parsing (TransformInterceptor wrapper)
      final unwrappedData = _unwrapResponse(response.data);
      
      if (unwrappedData != null) {
        developer.log('[RemoteDataSource:UnlockWeek] ✓ Successfully unwrapped response');
        developer.log('[RemoteDataSource:UnlockWeek]   - currentPlanId: ${unwrappedData['currentPlanId']}');
        developer.log('[RemoteDataSource:UnlockWeek]   - message: ${unwrappedData['message']}');
        developer.log('[RemoteDataSource:UnlockWeek]   - balance: ${unwrappedData['balance']}');
        developer.log('[RemoteDataSource:UnlockWeek]   - monthlyBalance: ${unwrappedData['monthlyBalance']}');
      } else {
        developer.log('[RemoteDataSource:UnlockWeek] ⚠️ Failed to unwrap response data');
      }
      
      return unwrappedData;
    } on DioException catch (e) {
      developer.log('[RemoteDataSource:UnlockWeek] ✗ Error: ${e.message}', error: e);
      developer.log('[RemoteDataSource:UnlockWeek] Error response: ${e.response?.data}');
      developer.log('[RemoteDataSource:UnlockWeek] Error status: ${e.response?.statusCode}');
      throw Exception(e.response?.data['message'] ?? 'Failed to request next week');
    }
  }

  // ========== CHECK-INS API - DATE RANGE ==========

  /// Get check-ins by date range (for calendar view)
  /// GET /checkins/range/start/:startDate/end/:endDate
  Future<List<Map<String, dynamic>>> getCheckInsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final startStr = startDate.toIso8601String();
      final endStr = endDate.toIso8601String();
      developer.log('[RemoteDataSource:CheckIns] getCheckInsByDateRange: $startStr to $endStr');

      final response = await _dio.get('/checkins/range/start/$startStr/end/$endStr');

      if (response.data is List) {
        developer.log('[RemoteDataSource:CheckIns] ✓ Loaded ${response.data.length} check-ins');
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['data'] is List) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }

      return [];
    } on DioException catch (e) {
      developer.log('[RemoteDataSource:CheckIns] ✗ Error: ${e.message}', error: e);
      throw Exception(e.response?.data['message'] ?? 'Failed to load check-ins');
    }
  }
}

/// Riverpod provider for RemoteDataSource
/// Creates a singleton instance of RemoteDataSource with Dio and FlutterSecureStorage
@riverpod
RemoteDataSource remoteDataSource(RemoteDataSourceRef ref) {
  final dio = Dio();
  final storage = FlutterSecureStorage();
  return RemoteDataSource(dio, storage);
}
