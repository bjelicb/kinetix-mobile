import 'package:flutter/material.dart';

class AppColors {
  // Modern Premium Color Palette (Glovo-inspired)
  
  // Base Colors
  static const Color background = Color(0xFF0A0A0A); // Almost Black
  static const Color backgroundSecondary = Color(0xFF121212); // Slightly lighter
  static const Color surface = Color(0xFF1E1E1E); // Dark Grey
  static const Color surface1 = Color(0xFF252525); // Lighter surface
  static const Color surface2 = Color(0xFF2D2D2D); // Even lighter
  static const Color surface3 = Color(0xFF353535); // Lightest surface
  
  // Primary Gradient Colors (Purple-Pink)
  static const Color primaryStart = Color(0xFF6366F1); // Indigo
  static const Color primaryMiddle = Color(0xFF8B5CF6); // Purple
  static const Color primaryEnd = Color(0xFFEC4899); // Pink
  static const Color primary = primaryMiddle; // Default primary
  
  // Secondary Gradient Colors (Blue-Cyan, darker for contrast)
  static const Color secondaryStart = Color(0xFF0EA5E9);
  static const Color secondaryEnd = Color(0xFF3B82F6);
  static const Color secondary = secondaryStart; // Default secondary
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentYellow = Color(0xFFFFD23F);
  static const Color accentGreen = Color(0xFF10B981);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB3B3B3); // Grey
  static const Color textTertiary = Color(0xFF808080); // Lighter grey
  static const Color textDisabled = Color(0xFF4A4A4A); // Disabled text
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF047857);
  static const Color warning = Color(0xFFFFAA00);
  static const Color warningDark = Color(0xFFFF8800);
  static const Color error = Color(0xFFFF003C);
  static const Color errorDark = Color(0xFFCC0029);
  static const Color info = Color(0xFF00D4FF);
  
  // Glassmorphism
  static Color glassBackground = Colors.white.withValues(alpha: 0.1);
  static Color glassBackgroundLight = Colors.white.withValues(alpha: 0.15);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.3);
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryStart, primaryMiddle, primaryEnd],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryStart, secondaryEnd],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundSecondary],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surface1],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successDark],
    stops: [0.0, 1.0],
  );
  
  // Neon Glow Colors
  static Color neonGlowPrimary = primary.withValues(alpha: 0.5);
  static Color neonGlowSecondary = secondary.withValues(alpha: 0.5);
  static Color neonGlowSuccess = success.withValues(alpha: 0.5);
  
  // Admin-specific subtle colors
  static const Color adminCardBackground = surface;
  static const Color adminCardBorder = Color(0xFF2D2D2D);
  static Color adminAccent = primary.withValues(alpha: 0.3);
  static Color adminIconColor = primary.withValues(alpha: 0.6);
}

// Trainer-Specific Color Palettes
class TrainerThemes {
  // Milan Theme - "War Room" Aesthetic
  static const Color milanPrimary = Color(0xFFFF003C);      // Crimson Red
  static const Color milanSecondary = Color(0xFFCC0029);    // Dark Red
  static const Color milanAccent = Color(0xFFFF4466);       // Bright Red
  
  // Aca Theme - "High-Tech Lab" Aesthetic  
  static const Color acaPrimary = Color(0xFF00F0FF);         // Electric Cyan
  static const Color acaSecondary = Color(0xFF0EA5E9);       // Bright Blue
  static const Color acaAccent = Color(0xFF22D4FF);          // Light Cyan
  
  // Gradients
  static const LinearGradient milanGradient = LinearGradient(
    colors: [milanPrimary, milanSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient acaGradient = LinearGradient(
    colors: [acaPrimary, acaSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Neutral theme (fallback)
  static const LinearGradient neutralGradient = AppColors.primaryGradient;
}

class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
}
