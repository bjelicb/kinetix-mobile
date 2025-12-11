import 'package:shared_preferences/shared_preferences.dart';

/// Data class for settings
class SettingsData {
  final bool workoutReminders;
  final bool checkInReminders;
  final bool pushNotifications;
  final bool autoSync;

  SettingsData({
    required this.workoutReminders,
    required this.checkInReminders,
    required this.pushNotifications,
    required this.autoSync,
  });
}

/// Service for managing settings persistence
class SettingsService {
  /// Loads all settings from SharedPreferences
  static Future<SettingsData> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsData(
      workoutReminders: prefs.getBool('workout_reminders') ?? false,
      checkInReminders: prefs.getBool('check_in_reminders') ?? false,
      pushNotifications: prefs.getBool('push_notifications') ?? true,
      autoSync: prefs.getBool('auto_sync') ?? true,
    );
  }

  /// Saves a single setting to SharedPreferences
  static Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

