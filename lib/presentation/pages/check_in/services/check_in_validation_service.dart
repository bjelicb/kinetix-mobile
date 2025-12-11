import 'package:flutter/foundation.dart' show debugPrint;

/// Validation result for check-in date
class CheckInValidationResult {
  final bool isValid;
  final String? warningMessage;

  CheckInValidationResult({required this.isValid, this.warningMessage});
}

/// Service for check-in validation logic
class CheckInValidationService {
  /// Validate check-in date against workout date
  /// Returns validation result with optional warning
  static CheckInValidationResult validateCheckInDate(DateTime checkInDate, DateTime workoutDate) {
    debugPrint('[CheckIn:DateValidation] Check-in date: $checkInDate');
    debugPrint('[CheckIn:DateValidation] Workout date: $workoutDate');

    // Check if dates match (same day)
    final checkInDay = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final workoutDay = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);

    if (!checkInDay.isAtSameMomentAs(workoutDay)) {
      debugPrint('[CheckIn:DateValidation] WARNING - Date mismatch detected');
      return CheckInValidationResult(
        isValid: false,
        warningMessage: 'Check-in date doesn\'t match workout date',
      );
    }

    return CheckInValidationResult(isValid: true);
  }
}

