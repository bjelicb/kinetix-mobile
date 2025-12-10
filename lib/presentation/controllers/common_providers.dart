import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Dio HTTP client instance
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// Provider for FlutterSecureStorage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

