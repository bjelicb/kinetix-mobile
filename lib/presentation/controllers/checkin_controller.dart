import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/checkin.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/mappers/checkin_mapper.dart';

part 'checkin_controller.g.dart';

@riverpod
class CheckInController extends _$CheckInController {
  late LocalDataSource _localDataSource;
  
  @override
  FutureOr<List<CheckIn>> build() async {
    _localDataSource = LocalDataSource();
    final collections = await _localDataSource.getAllCheckIns();
    return collections.map((c) => CheckInMapper.toEntity(c)).toList();
  }
  
  Future<void> deleteCheckIn(String id) async {
    final isarId = int.tryParse(id);
    if (isarId == null) throw Exception('Invalid check-in ID');
    
    await _localDataSource.deleteCheckIn(isarId);
    // Refresh check-ins
    state = AsyncValue.data(await _localDataSource.getAllCheckIns()
        .then((collections) => collections.map((c) => CheckInMapper.toEntity(c)).toList()));
  }
  
  /// Check if user should be required to check in
  /// Returns true if:
  /// - User is a CLIENT (not TRAINER)
  /// - User has a workout scheduled for today
  /// - The workout is NOT completed
  /// - User has NOT already checked in today
  Future<bool> shouldRequireCheckIn(User? user) async {
    // If no user, no check-in required
    if (user == null) return false;
    
    // Only clients need to check in
    if (user.role != 'CLIENT') return false;
    
    // Check if user already checked in today
    final todayCheckIn = await _localDataSource.getTodayCheckIn();
    if (todayCheckIn != null) return false;
    
    // Check if user has workouts scheduled for today
    final todayWorkouts = await _localDataSource.getTodayWorkouts();
    
    // No workouts today, no check-in required
    if (todayWorkouts.isEmpty) return false;
    
    // Check if any workout is not completed
    // If all workouts are completed, no check-in required
    final hasIncompleteWorkout = todayWorkouts.any((workout) => !workout.isCompleted);
    
    return hasIncompleteWorkout;
  }
}

