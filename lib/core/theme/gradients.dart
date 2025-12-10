import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  // Primary Gradients
  static const primary = AppColors.primaryGradient;
  static const secondary = AppColors.secondaryGradient;
  static const background = AppColors.backgroundGradient;
  static const card = AppColors.cardGradient;
  static const success = AppColors.successGradient;
  
  // Error Gradient (for paywall, critical alerts)
  static const error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.error, Color(0xFFD32F2F)],
  );
  
  // Custom Gradients
  static const purplePink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
  );
  
  static const cyanBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondaryStart, AppColors.primaryStart],
  );
  
  static const orangePink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentOrange, AppColors.primaryEnd],
  );
  
  static const yellowOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentYellow, AppColors.accentOrange],
  );
  
  // Radial Gradients
  static const radialPrimary = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.5,
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
  );
  
  static const radialSecondary = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [AppColors.secondaryStart, AppColors.secondaryEnd],
  );
  
  // Glassmorphism Gradient
  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.05),
    ],
  );
  
  // Trainer-Specific Gradients
  static const milan = TrainerThemes.milanGradient;
  static const aca = TrainerThemes.acaGradient;
  static const neutral = TrainerThemes.neutralGradient;
  
  // Login Background Gradient
  static const loginBackground = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      AppColors.primaryStart, // Subtle primary accent in the middle
      AppColors.background,
      AppColors.background,
      AppColors.background,
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );
}

