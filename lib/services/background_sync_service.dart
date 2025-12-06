import 'package:flutter/foundation.dart' show debugPrint;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../data/datasources/local_data_source.dart';
import '../data/datasources/remote_data_source.dart';
import 'sync_manager.dart';

class BackgroundSyncService {
  static const String _syncTaskName = 'kinetix_sync_task';
  static const String _oneOffTaskName = 'kinetix_sync_oneoff';

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('Periodic sync task registered');
  }

  static Future<void> triggerOneOffSync() async {
    await Workmanager().registerOneOffTask(
      _oneOffTaskName,
      _oneOffTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('One-off sync task triggered');
  }

  static Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName(_syncTaskName);
    await Workmanager().cancelByUniqueName(_oneOffTaskName);
    debugPrint('Sync tasks cancelled');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background sync task started: $task');

      // Initialize services
      final storage = FlutterSecureStorage();
      final localDataSource = LocalDataSource();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      final syncManager = SyncManager(localDataSource, remoteDataSource);

      // Perform sync
      await syncManager.sync();

      debugPrint('Background sync task completed successfully');
      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint('Background sync task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}
