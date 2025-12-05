import 'package:flutter/services.dart';

class AppHaptic {
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
  
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }
  
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }
  
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
  
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
  
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }
}

