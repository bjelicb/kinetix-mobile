import 'package:flutter/foundation.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../../domain/entities/user.dart';
import '../../../../services/exercise_library_service.dart';

/// Service for loading dashboard data
class DashboardDataService {
  /// Load balance data for client
  /// Returns null on error (silent failure - balance is not critical)
  static Future<Map<String, dynamic>?> loadBalance(
    RemoteDataSource remoteDataSource,
    User? user,
  ) async {
    if (user?.role != 'CLIENT') {
      debugPrint('[DashboardDataService] Skipping balance load - user is not CLIENT (role: ${user?.role})');
      return null;
    }

    debugPrint('[DashboardDataService] loadBalance START - Loading balance for client');

    try {
      debugPrint('[DashboardDataService] Calling getGamificationStatus API...');
      final status = await remoteDataSource.getGamificationStatus();

      debugPrint('[DashboardDataService] API Response: $status');
      debugPrint('[DashboardDataService] Balance: ${status['balance']}, MonthlyBalance: ${status['monthlyBalance']}');

      final balance = status['balance'] ?? 0.0;
      final monthlyBalance = status['monthlyBalance'] ?? 0.0;

      final balanceData = {
        'balance': balance,
        'monthlyBalance': monthlyBalance,
        'lastBalanceReset': status['lastBalanceReset'],
      };

      debugPrint('[DashboardDataService] loadBalance SUCCESS - Balance: $balance€, Monthly: $monthlyBalance€');
      
      // Log paywall condition for debugging
      if (monthlyBalance >= 0) {
        debugPrint('[DashboardDataService] Paywall will NOT be shown - monthlyBalance is not negative ($monthlyBalance€)');
      } else {
        debugPrint('[DashboardDataService] Paywall condition MET - monthlyBalance is negative ($monthlyBalance€), paywall should be shown');
      }
      
      return balanceData;
    } catch (e, stackTrace) {
      debugPrint('[DashboardDataService] loadBalance ERROR: $e');
      debugPrint('[DashboardDataService] Stack trace: $stackTrace');
      // Silently fail - balance is not critical
      return null;
    }
  }

  /// Load latest weigh-in data for client
  /// Returns null on error or if no weigh-in found
  static Future<Map<String, dynamic>?> loadWeighIn(
    RemoteDataSource remoteDataSource,
    User? user,
  ) async {
    if (user?.role != 'CLIENT') {
      debugPrint('[DashboardDataService] Skipping weigh-in load - user is not CLIENT (role: ${user?.role})');
      return null;
    }

    debugPrint('[DashboardDataService] loadWeighIn START - Loading latest weigh-in for client');

    try {
      debugPrint('[DashboardDataService] Calling getLatestWeighIn API...');
      final latestWeighIn = await remoteDataSource.getLatestWeighIn();

      debugPrint('[DashboardDataService] getLatestWeighIn API Response: $latestWeighIn');

      if (latestWeighIn != null) {
        debugPrint('[DashboardDataService] loadWeighIn SUCCESS - Weight: ${latestWeighIn['weight']}kg, Date: ${latestWeighIn['date']}');
      } else {
        debugPrint('[DashboardDataService] loadWeighIn SUCCESS - No weigh-in found');
      }

      return latestWeighIn;
    } catch (e, stackTrace) {
      debugPrint('[DashboardDataService] loadWeighIn ERROR: $e');
      debugPrint('[DashboardDataService] Stack trace: $stackTrace');
      // Silently fail - weigh-in is not critical
      return null;
    }
  }

  /// Load available muscle groups from exercise library
  /// Returns empty list on error
  static Future<List<String>> loadMuscleGroups() async {
    try {
      final exercises = await ExerciseLibraryService.instance.getAllExercises();
      final muscleGroups = exercises.map((e) => e.targetMuscle).toSet().toList();
      return muscleGroups;
    } catch (e) {
      debugPrint('[DashboardDataService] loadMuscleGroups ERROR: $e');
      // Ignore errors - return empty list
      return [];
    }
  }
}

