import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/analytics_service.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

part 'analytics_controller.g.dart';

/// Model for client analytics data
class ClientAnalytics {
  final String id;
  final String name;
  final double overallAdherence;
  final int totalWorkouts;
  final int completedWorkouts;
  final List<double> weeklyAdherence;
  final Map<String, List<Map<String, double>>> strengthProgression;
  
  ClientAnalytics({
    required this.id,
    required this.name,
    required this.overallAdherence,
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.weeklyAdherence,
    required this.strengthProgression,
  });
}

@riverpod
class AnalyticsController extends _$AnalyticsController {
  late AnalyticsService _analyticsService;
  
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final storage = FlutterSecureStorage();
    final localDataSource = LocalDataSource();
    final dio = Dio();
    final remoteDataSource = RemoteDataSource(dio, storage);
    _analyticsService = AnalyticsService(remoteDataSource, localDataSource);
    
    return await _analyticsService.getTrainerClients();
  }
  
  /// Get analytics data for a specific client
  Future<ClientAnalytics> getClientAnalytics(String clientId, String clientName) async {
    final weeklyAdherence = await _analyticsService.calculateWeeklyAdherence(clientId);
    final overallAdherence = await _analyticsService.calculateOverallAdherence(clientId);
    final totalWorkouts = await _analyticsService.getTotalWorkouts(clientId);
    final completedWorkouts = await _analyticsService.getCompletedWorkouts(clientId);
    final strengthProgression = await _analyticsService.getStrengthProgression(clientId: clientId);
    
    return ClientAnalytics(
      id: clientId,
      name: clientName,
      overallAdherence: overallAdherence,
      totalWorkouts: totalWorkouts,
      completedWorkouts: completedWorkouts,
      weeklyAdherence: weeklyAdherence,
      strengthProgression: strengthProgression,
    );
  }
  
  /// Refresh clients list
  Future<void> refreshClients() async {
    state = const AsyncValue.loading();
    try {
      final clients = await _analyticsService.getTrainerClients();
      state = AsyncValue.data(clients);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
