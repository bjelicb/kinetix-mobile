import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {
  // Backend API Base URL
  // Dynamically selects URL based on platform:
  // - Web and desktop: uses localhost
  // - Mobile (Android/iOS): uses computer's IP address
  // Find your IP with: ipconfig (Windows) or ifconfig (Mac/Linux)
  static String get baseUrl {
    // Web platform koristi localhost
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    // Windows desktop koristi localhost
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:3000/api';
    }
    
    // Android/iOS koriste IP adresu računara
    return 'http://192.168.0.27:3000/api';
  }
  
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
  
  // Workout Endpoints
  static const String workoutsToday = '/workouts/today';
  static const String workoutsWeek = '/workouts/week';
  static const String workoutsHistory = '/workouts/history';
  static const String workoutsLog = '/workouts/log';
  
  // Client Endpoints
  static const String clientsCurrentPlan = '/clients/current-plan';
  
  // Trainer Endpoints
  static const String trainersClients = '/trainers/clients';
  
  // Gamification Endpoints
  static const String gamificationStatus = '/gamification/status';
  
  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

