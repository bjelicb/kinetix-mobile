import 'isar_service.dart';

class BootstrapService {
  static Future<void> initialize() async {
    // Initialize Isar (returns null on web, which is fine)
    await IsarService.instance;
    
    // Backend not ready - skip Dio/RemoteDataSource initialization
    // All API calls will use MockRemoteDataSource instead
    
    // Add a small delay to ensure everything is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ready for use
  }
}

