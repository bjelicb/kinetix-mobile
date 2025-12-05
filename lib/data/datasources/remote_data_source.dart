import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  
  RemoteDataSource(this._dio, this._storage) {
    // DISABLED: Backend not ready - don't configure Dio
    // _dio.options.baseUrl = ApiConstants.baseUrl;
    // _dio.options.connectTimeout = ApiConstants.connectTimeout;
    // _dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    // 
    // _dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (options, handler) async {
    //     final token = await _storage.read(key: AppConstants.accessTokenKey);
    //     if (token != null) {
    //       options.headers[ApiConstants.authorizationHeader] =
    //           '${ApiConstants.bearerPrefix}$token';
    //     }
    //     handler.next(options);
    //   },
    //   onError: (error, handler) async {
    //     if (error.response?.statusCode == 401) {
    //       // Token expired, try refresh
    //       final refreshed = await _refreshToken();
    //       if (refreshed) {
    //         final token = await _storage.read(key: AppConstants.accessTokenKey);
    //         error.requestOptions.headers[ApiConstants.authorizationHeader] =
    //             '${ApiConstants.bearerPrefix}$token';
    //         final response = await _dio.fetch(error.requestOptions);
    //         handler.resolve(response);
    //         return;
    //       }
    //     }
    //     handler.next(error);
    //   },
    // ));
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
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }
  
  // Auth Methods - DISABLED: Backend not ready, use MockRemoteDataSource instead
  Future<Map<String, dynamic>> login(String email, String password) async {
    throw UnimplementedError('Backend not ready - use MockRemoteDataSource');
  }
  
  Future<Map<String, dynamic>> register(String email, String password, String name, String role) async {
    throw UnimplementedError('Backend not ready - use MockRemoteDataSource');
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    throw UnimplementedError('Backend not ready - use MockRemoteDataSource');
  }
  
  // Sync Methods - DISABLED: Backend not ready
  Future<Map<String, dynamic>> syncBatch(Map<String, dynamic> data) async {
    throw UnimplementedError('Backend not ready');
  }
  
  Future<Map<String, dynamic>> getSyncChanges(String since) async {
    throw UnimplementedError('Backend not ready');
  }
  
  // Media Methods - DISABLED: Backend not ready
  Future<Map<String, dynamic>> getUploadSignature() async {
    throw UnimplementedError('Backend not ready');
  }
}

