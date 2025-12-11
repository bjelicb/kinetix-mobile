import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/local_data_source.dart';
import '../../../../data/mappers/checkin_mapper.dart';
import '../../../../domain/entities/checkin.dart';

/// Result of check-in status validation
class CheckInStatusResult {
  final bool hasValidCheckIn;
  final CheckIn? checkIn;

  CheckInStatusResult({
    required this.hasValidCheckIn,
    this.checkIn,
  });
}

/// Service for validating workout prerequisites
class WorkoutValidationService {
  /// Check if user has a valid check-in for today
  /// Returns CheckInStatusResult with validation status
  static Future<CheckInStatusResult> checkCheckInStatus() async {
    debugPrint('[WorkoutValidationService] checkCheckInStatus START');
    try {
      final localDataSource = LocalDataSource();
      debugPrint('[WorkoutValidationService] Checking for today\'s check-in...');
      final todayCheckIn = await localDataSource.getTodayCheckIn();
      
      debugPrint('[WorkoutValidationService] Today check-in result: ${todayCheckIn != null ? "FOUND" : "NOT FOUND"}');
      if (todayCheckIn != null) {
        debugPrint('[WorkoutValidationService] Check-in ID: ${todayCheckIn.id}, Timestamp: ${todayCheckIn.timestamp}');
      }
      
      debugPrint('[WorkoutValidationService] Check-in status: ${todayCheckIn != null ? "VALID" : "INVALID"}');
      
      return CheckInStatusResult(
        hasValidCheckIn: todayCheckIn != null,
        checkIn: todayCheckIn != null ? CheckInMapper.toEntity(todayCheckIn) : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[WorkoutValidationService] Error checking check-in status: $e');
      debugPrint('[WorkoutValidationService] Stack trace: $stackTrace');
      return CheckInStatusResult(hasValidCheckIn: false);
    }
  }

  /// Show check-in required snackbar and navigate to check-in page
  static void showCheckInRequired(BuildContext context) {
    debugPrint('[WorkoutValidationService] No valid check-in, redirecting to check-in page');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must check in before starting a workout'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
        ),
      );
      context.go('/check-in');
    });
  }
}

