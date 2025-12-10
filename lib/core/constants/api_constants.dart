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
    // VAŽNO: Proverite da li je ova IP adresa ispravna!
    // Pronađite IP adresu sa: ipconfig (Windows) ili ifconfig (Mac/Linux)
    // Telefon i računar moraju biti na istoj WiFi mreži
    // Ako se ne možete ulogovati, proverite IP adresu i ažurirajte je ovde
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
  static String checkInsByDateRange(String startDate, String endDate) => 
      '/checkins/range/start/$startDate/end/$endDate';
  static String checkInDelete(String checkInId) => '/checkins/$checkInId';
  
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
  static const String gamificationBalance = '/gamification/balance';
  static const String gamificationClearBalance = '/gamification/clear-balance';
  static String gamificationMessages(String clientId) => '/gamification/messages/$clientId';
  static String gamificationMarkMessageRead(String messageId) => '/gamification/messages/$messageId/read';
  
  // Admin Endpoints
  static const String adminUsers = '/admin/users';
  static const String adminStats = '/admin/stats';
  static const String adminAssignClient = '/admin/assign-client';
  static const String adminPlans = '/admin/plans';
  static const String adminWorkoutsAll = '/admin/workouts/all';
  static const String adminWorkoutsStats = '/admin/workouts/stats';
  static String adminUpdateUser(String userId) => '/admin/users/$userId';
  static String adminDeleteUser(String userId) => '/admin/users/$userId';
  static String adminUpdateUserStatus(String userId) => '/admin/users/$userId/status';
  static String adminUpdateWorkoutStatus(String workoutId) => '/admin/workouts/$workoutId/status';
  static String adminDeleteWorkout(String workoutId) => '/admin/workouts/$workoutId';
  
  // Plan Management Endpoints
  static const String plans = '/plans';
  static String planById(String planId) => '/plans/$planId';
  static String planUpdate(String planId) => '/plans/$planId';
  static String planDelete(String planId) => '/plans/$planId';
  static String planAssign(String planId) => '/plans/$planId/assign';
  static String planDuplicate(String planId) => '/plans/$planId/duplicate';
  static String planCanUnlockNextWeek(String clientId) => '/plans/unlock-next-week/$clientId';
  static String planRequestNextWeek(String clientId) => '/plans/request-next-week/$clientId';
  
  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

