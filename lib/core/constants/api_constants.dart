class ApiConstants {
  // Backend API Base URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  
  // Sync Endpoints
  static const String sync = '/training/sync';
  static const String syncChanges = '/training/sync/changes';
  
  // Media Endpoints
  static const String mediaSignature = '/media/signature';
  
  // Check-in Endpoints
  static const String checkIns = '/checkins';
  
  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

