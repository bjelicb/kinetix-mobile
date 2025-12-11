import '../../../../data/datasources/local_data_source.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../../services/sync_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Result of sync operation
class SyncResult {
  final bool success;
  final String? error;
  final DateTime? lastSyncTime;

  SyncResult({
    required this.success,
    this.error,
    this.lastSyncTime,
  });
}

/// Service for sync operations
class SettingsSyncService {
  /// Performs manual sync and returns the result
  static Future<SyncResult> performManualSync() async {
    try {
      final storage = FlutterSecureStorage();
      final localDataSource = LocalDataSource();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      final syncManager = SyncManager(localDataSource, remoteDataSource);

      await syncManager.sync();

      return SyncResult(
        success: true,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

