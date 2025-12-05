import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  
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
}

