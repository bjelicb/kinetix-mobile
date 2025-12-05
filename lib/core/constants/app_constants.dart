class AppConstants {
  // App Info
  static const String appName = 'Kinetix';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  
  // Sync Settings
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  
  // Workout Settings
  static const int defaultRestSeconds = 60;
  static const double minWeight = 0.0;
  static const double maxWeight = 500.0;
  static const int minReps = 1;
  static const int maxReps = 100;
  static const double minRpe = 1.0;
  static const double maxRpe = 10.0;
}

