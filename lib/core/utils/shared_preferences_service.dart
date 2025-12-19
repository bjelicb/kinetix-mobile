import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class SharedPreferencesService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _skipCheckInUntilKey = 'skip_check_in_until';
  static const String _requiresNewCheckInKey = 'requires_new_check_in';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> isOnboardingCompleted() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs?.getBool(_onboardingCompletedKey) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs?.setBool(_onboardingCompletedKey, completed);
  }

  /// Check if user has chosen to skip check-in temporarily
  static Future<bool> isCheckInSkipped() async {
    debugPrint('[SharedPreferencesService] isCheckInSkipped() called');
    if (_prefs == null) {
      await init();
    }
    final skipUntilMs = _prefs?.getInt(_skipCheckInUntilKey);
    debugPrint('[SharedPreferencesService] Skip until timestamp: $skipUntilMs');

    if (skipUntilMs == null) {
      debugPrint('[SharedPreferencesService] No skip flag found - returning FALSE');
      return false;
    }

    final skipUntil = DateTime.fromMillisecondsSinceEpoch(skipUntilMs);
    final now = DateTime.now();
    debugPrint('[SharedPreferencesService] Skip until: $skipUntil');
    debugPrint('[SharedPreferencesService] Current time: $now');

    // If skip time has passed, clear it and return false
    if (now.isAfter(skipUntil)) {
      debugPrint('[SharedPreferencesService] Skip time expired - clearing flag and returning FALSE');
      await clearCheckInSkip();
      return false;
    }

    debugPrint('[SharedPreferencesService] Skip is active - returning TRUE');
    return true;
  }

  /// Skip check-in for the rest of today (until midnight)
  static Future<void> skipCheckInForToday() async {
    debugPrint('[SharedPreferencesService] skipCheckInForToday() called');
    if (_prefs == null) {
      await init();
    }

    // Set skip until end of today (midnight)
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    debugPrint('[SharedPreferencesService] Setting skip until: $endOfDay (${endOfDay.millisecondsSinceEpoch})');

    await _prefs?.setInt(_skipCheckInUntilKey, endOfDay.millisecondsSinceEpoch);
    debugPrint('[SharedPreferencesService] Skip flag successfully set');
    
    // Mark check-in requirement as fulfilled for this session
    await markCheckInFulfilled();
  }

  /// Clear the check-in skip
  static Future<void> clearCheckInSkip() async {
    debugPrint('[SharedPreferencesService] clearCheckInSkip() called - removing skip flag');
    if (_prefs == null) {
      await init();
    }
    await _prefs?.remove(_skipCheckInUntilKey);
    debugPrint('[SharedPreferencesService] Skip flag cleared');
  }

  /// Clear check-in session status (for logout/login)
  /// This does NOT delete check-in history from database
  static Future<void> clearCheckInSession() async {
    debugPrint('[SharedPreferencesService] ═══════════════════════════════════════');
    debugPrint('[SharedPreferencesService] clearCheckInSession() called');
    debugPrint('[SharedPreferencesService] Clearing check-in session for new login/logout');
    if (_prefs == null) {
      await init();
    }
    await _prefs?.remove(_skipCheckInUntilKey);
    await _prefs?.setBool(_requiresNewCheckInKey, true);
    debugPrint('[SharedPreferencesService] ✅ Skip flag cleared');
    debugPrint('[SharedPreferencesService] ✅ Requires new check-in flag SET to TRUE');
    debugPrint('[SharedPreferencesService] ✅ Check-in session cleared - fresh check-in will be required');
    debugPrint('[SharedPreferencesService] ═══════════════════════════════════════');
  }

  /// Check if a new check-in is required for this session
  static Future<bool> isNewCheckInRequired() async {
    debugPrint('[SharedPreferencesService] isNewCheckInRequired() called');
    if (_prefs == null) {
      await init();
    }
    final required = _prefs?.getBool(_requiresNewCheckInKey) ?? false;
    debugPrint('[SharedPreferencesService] Requires new check-in: $required');
    return required;
  }

  /// Mark that check-in requirement has been fulfilled for this session
  static Future<void> markCheckInFulfilled() async {
    debugPrint('[SharedPreferencesService] markCheckInFulfilled() called');
    debugPrint('[SharedPreferencesService] Setting requires new check-in flag to FALSE');
    if (_prefs == null) {
      await init();
    }
    await _prefs?.setBool(_requiresNewCheckInKey, false);
    debugPrint('[SharedPreferencesService] ✅ Check-in requirement fulfilled for this session');
  }
}
