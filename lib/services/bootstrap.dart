import 'isar_service.dart';
import 'background_sync_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class BootstrapService {
  static Future<void> initialize() async {
    // Initialize Isar (returns null on web, which is fine)
    await IsarService.instance;
    
    // Backend is ready - Dio/RemoteDataSource will be initialized
    // when needed (in AuthController, SyncManager, etc.)
    
    // Initialize background sync (only on mobile platforms)
    if (!kIsWeb) {
      try {
        await BackgroundSyncService.initialize();
        await BackgroundSyncService.registerPeriodicSync();
        debugPrint('Background sync service initialized');
      } catch (e) {
        debugPrint('Error initializing background sync: $e');
        // Continue even if background sync fails
      }
    }
    
    // Add a small delay to ensure everything is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ready for use
  }
}

