import 'package:flutter/foundation.dart' show debugPrint;

/// Utility class for consistent date/time handling across the app
/// Handles timezone conversions, date normalization, and range checks
class AppDateUtils {
  /// Normalize date to start of day in local timezone (00:00:00.000)
  static DateTime normalizeToStartOfDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    debugPrint('[DateUtils:Normalize] Input: $date → Start of day: $normalized');
    return normalized;
  }
  
  /// Normalize date to end of day in local timezone (23:59:59.999)
  static DateTime normalizeToEndOfDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    debugPrint('[DateUtils:Normalize] Input: $date → End of day: $normalized');
    return normalized;
  }
  
  /// Check if date is today (in local timezone)
  static bool isToday(DateTime date) {
    final today = normalizeToStartOfDay(DateTime.now());
    final checkDate = normalizeToStartOfDay(date);
    final result = today.isAtSameMomentAs(checkDate);
    debugPrint('[DateUtils:IsToday] Check date: $checkDate, Today: $today, Result: $result');
    return result;
  }
  
  /// Check if date range is active (start <= today <= end)
  /// Both start and end dates are inclusive
  static bool isDateRangeActive(DateTime startDate, DateTime endDate) {
    final today = normalizeToStartOfDay(DateTime.now());
    final start = normalizeToStartOfDay(startDate);
    final end = normalizeToEndOfDay(endDate);
    
    final result = (today.isAfter(start) || today.isAtSameMomentAs(start)) &&
           (today.isBefore(end) || today.isAtSameMomentAs(end));
    
    debugPrint('[DateUtils:RangeCheck] Today: $today, Range: $start - $end, Active: $result');
    return result;
  }
  
  /// Calculate days remaining until end date
  /// Returns negative if date has passed
  static int daysUntil(DateTime targetDate) {
    final today = normalizeToStartOfDay(DateTime.now());
    final target = normalizeToStartOfDay(targetDate);
    final difference = target.difference(today).inDays;
    debugPrint('[DateUtils:DaysUntil] Target: $target, Today: $today, Days remaining: $difference');
    return difference;
  }
  
  /// Check if date is in the past (before today)
  static bool isPast(DateTime date) {
    final today = normalizeToStartOfDay(DateTime.now());
    final checkDate = normalizeToStartOfDay(date);
    final result = checkDate.isBefore(today);
    debugPrint('[DateUtils:IsPast] Check date: $checkDate, Today: $today, Result: $result');
    return result;
  }
  
  /// Check if date is in the future (after today)
  static bool isFuture(DateTime date) {
    final today = normalizeToStartOfDay(DateTime.now());
    final checkDate = normalizeToStartOfDay(date);
    final result = checkDate.isAfter(today);
    debugPrint('[DateUtils:IsFuture] Check date: $checkDate, Today: $today, Result: $result');
    return result;
  }
  
  /// Convert local date to UTC for API
  static DateTime toUtc(DateTime localDate) {
    final utc = localDate.toUtc();
    debugPrint('[DateUtils:Timezone] Local: $localDate → UTC: $utc');
    return utc;
  }
  
  /// Convert UTC date from API to local
  static DateTime fromUtc(DateTime utcDate) {
    final local = utcDate.toLocal();
    debugPrint('[DateUtils:Timezone] UTC: $utcDate → Local: $local');
    return local;
  }
  
  /// Check if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    final normalized1 = normalizeToStartOfDay(date1);
    final normalized2 = normalizeToStartOfDay(date2);
    final result = normalized1.isAtSameMomentAs(normalized2);
    debugPrint('[DateUtils:SameDay] Date1: $normalized1, Date2: $normalized2, Result: $result');
    return result;
  }
  
  /// Format date for display (e.g., "Jan 15, 2024")
  static String formatDisplayDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  /// Format date for API (ISO 8601 string)
  static String formatApiDate(DateTime date) {
    return date.toIso8601String();
  }
  
  /// Parse date from API (ISO 8601 string)
  static DateTime parseApiDate(String dateString) {
    return DateTime.parse(dateString);
  }
}

