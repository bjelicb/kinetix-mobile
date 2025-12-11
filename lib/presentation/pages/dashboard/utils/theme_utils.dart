import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart' show AppColors, TrainerThemes;
import '../../../../core/theme/gradients.dart';
import '../../../controllers/theme_controller.dart';

/// Theme utility functions for dashboard
class ThemeUtils {
  /// Get gradient based on trainer theme
  static LinearGradient getThemeGradient(TrainerTheme theme) {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanGradient;
      case TrainerTheme.aca:
        return TrainerThemes.acaGradient;
      case TrainerTheme.neutral:
        return AppGradients.primary;
    }
  }

  /// Get primary color based on trainer theme
  static Color getThemeColor(TrainerTheme theme) {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanPrimary;
      case TrainerTheme.aca:
        return TrainerThemes.acaPrimary;
      case TrainerTheme.neutral:
        return AppColors.primary;
    }
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

