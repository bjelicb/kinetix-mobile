import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/shared_preferences_service.dart';
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
  /// Skip check-in COUNTS as valid check-in - allows access to workout runner
  /// 
  /// SESSION-AWARE VALIDATION:
  /// - After login/logout: Requires NEW check-in regardless of existing check-ins
  /// - Returns TRUE only if: (new check-in NOT required) AND (skip flag is set OR actual check-in exists in database)
  /// - Returns FALSE if: new check-in IS required OR (no skip flag AND no check-in in database)
  static Future<CheckInStatusResult> checkCheckInStatus() async {
    debugPrint('[WorkoutValidationService] =====================================');
    debugPrint('[WorkoutValidationService] checkCheckInStatus START');
    debugPrint('[WorkoutValidationService] =====================================');
    try {
      // STEP 0: Check if a new check-in is required for this session (after login/logout)
      debugPrint('[WorkoutValidationService] Step 0: Checking if new check-in required for this session...');
      final requiresNewCheckIn = await SharedPreferencesService.isNewCheckInRequired();
      debugPrint('[WorkoutValidationService] New check-in required: $requiresNewCheckIn');
      
      if (requiresNewCheckIn) {
        debugPrint('[WorkoutValidationService] ❌ NEW CHECK-IN REQUIRED for this session');
        debugPrint('[WorkoutValidationService] User must check-in or skip after login/logout');
        debugPrint('[WorkoutValidationService] Returning: hasValidCheckIn = FALSE');
        debugPrint('[WorkoutValidationService] =====================================');
        return CheckInStatusResult(hasValidCheckIn: false);
      }
      
      // STEP 1: Check if user has skipped check-in for today
      // Skip check-in should allow access to workout runner (works on both mobile and web)
      debugPrint('[WorkoutValidationService] Step 1: Checking skip flag...');
      final isSkipped = await SharedPreferencesService.isCheckInSkipped();
      debugPrint('[WorkoutValidationService] Skip flag result: $isSkipped');
      
      if (isSkipped) {
        debugPrint('[WorkoutValidationService] ✅ SKIP FLAG SET - Treating as valid check-in');
        debugPrint('[WorkoutValidationService] Returning: hasValidCheckIn = TRUE');
        debugPrint('[WorkoutValidationService] =====================================');
        return CheckInStatusResult(hasValidCheckIn: true);
      }
      
      // STEP 2: Check for actual check-in in database
      debugPrint('[WorkoutValidationService] Step 2: Skip flag not set, checking database...');
      final localDataSource = LocalDataSource();
      final todayCheckIn = await localDataSource.getTodayCheckIn();
      
      debugPrint('[WorkoutValidationService] Database check-in result: ${todayCheckIn != null ? "FOUND" : "NOT FOUND"}');
      if (todayCheckIn != null) {
        debugPrint('[WorkoutValidationService] ✅ CHECK-IN FOUND in database');
        debugPrint('[WorkoutValidationService] Check-in ID: ${todayCheckIn.id}');
        debugPrint('[WorkoutValidationService] Check-in Timestamp: ${todayCheckIn.timestamp}');
        debugPrint('[WorkoutValidationService] Returning: hasValidCheckIn = TRUE');
      } else {
        debugPrint('[WorkoutValidationService] ⚠️ NO CHECK-IN FOUND in database');
        debugPrint('[WorkoutValidationService] Returning: hasValidCheckIn = FALSE');
      }
      
      debugPrint('[WorkoutValidationService] =====================================');
      
      return CheckInStatusResult(
        hasValidCheckIn: todayCheckIn != null,
        checkIn: todayCheckIn != null ? CheckInMapper.toEntity(todayCheckIn) : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[WorkoutValidationService] ❌ ERROR checking check-in status: $e');
      debugPrint('[WorkoutValidationService] Stack trace: $stackTrace');
      debugPrint('[WorkoutValidationService] Returning: hasValidCheckIn = FALSE (error fallback)');
      debugPrint('[WorkoutValidationService] =====================================');
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

