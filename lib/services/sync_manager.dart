import 'dart:io' as io show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:dio/dio.dart';
import '../data/datasources/local_data_source.dart';
import '../data/datasources/remote_data_source.dart';
import '../data/models/workout_collection.dart' if (dart.library.html) '../data/models/workout_collection_stub.dart';
import '../data/models/checkin_collection.dart' if (dart.library.html) '../data/models/checkin_collection_stub.dart';
import '../data/mappers/plan_mapper.dart';
import 'cloudinary_upload_service.dart';

/// Error types for categorization
enum SyncErrorType {
  network,
  auth,
  server,
  validation,
  unknown,
}

/// Sync result with partial success tracking
class SyncResult {
  final int successCount;
  final int failedCount;
  final int totalCount;
  final List<String> errors;
  
  SyncResult({
    required this.successCount,
    required this.failedCount,
    required this.totalCount,
    required this.errors,
  });
  
  bool get hasPartialSuccess => successCount > 0 && failedCount > 0;
  bool get isFullSuccess => successCount == totalCount && failedCount == 0;
  bool get isFullFailure => successCount == 0 && failedCount > 0;
}

class SyncManager {
  static const int _maxPullRetries = 3;
  static const int _maxPushRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);
  
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final CloudinaryUploadService _cloudinaryService;
  
  SyncManager(this._localDataSource, this._remoteDataSource)
      : _cloudinaryService = CloudinaryUploadService(_remoteDataSource);
  
  /// Categorize error type for better handling
  SyncErrorType _categorizeError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return SyncErrorType.network;
      }
      
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return SyncErrorType.auth;
      }
      
      if (statusCode != null && statusCode >= 500) {
        return SyncErrorType.server;
      }
      
      if (statusCode == 400 || statusCode == 422) {
        return SyncErrorType.validation;
      }
    }
    
    return SyncErrorType.unknown;
  }
  
  /// Get user-friendly error message
  String _getErrorMessage(dynamic error, SyncErrorType errorType) {
    switch (errorType) {
      case SyncErrorType.network:
        return 'Network connection error. Please check your internet connection.';
      case SyncErrorType.auth:
        return 'Authentication error. Please log in again.';
      case SyncErrorType.server:
        return 'Server error. Please try again later.';
      case SyncErrorType.validation:
        return 'Invalid data. Please check your input.';
      case SyncErrorType.unknown:
        return 'An unexpected error occurred: ${error.toString()}';
    }
  }
  
  /// Retry operation with exponential backoff
  /// Only retries network errors (not 401/403)
  Future<T> _retryWithBackoff<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    
    while (true) {
      try {
        return await operation();
      } catch (e) {
        final isNetworkError = e is DioException && (
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError
        );
        
        final isAuthError = e is DioException && (
          e.response?.statusCode == 401 ||
          e.response?.statusCode == 403
        );
        
        if (isAuthError) {
          debugPrint('[SyncManager:Retry] Non-retryable error (${e.response?.statusCode}) - Skipping retry');
          rethrow;
        }
        
        if (!isNetworkError || retryCount >= maxRetries) {
          if (retryCount >= maxRetries) {
            debugPrint('[SyncManager:Retry] Max retries reached - Queuing for next launch');
          }
          rethrow;
        }
        
        retryCount++;
        final delay = _initialRetryDelay * (1 << (retryCount - 1)); // Exponential: 1s, 2s, 4s
        
        debugPrint('[SyncManager:Retry] $operationName failed - Attempt $retryCount/$maxRetries after ${delay.inSeconds}s delay');
        debugPrint('[SyncManager:Retry] Network error - Retry scheduled');
        
        await Future.delayed(delay);
      }
    }
  }
  
  /// Main sync method - Media-First, then Push, then Pull
  Future<SyncResult?> sync() async {
    try {
      // Step 1: Media-First Sync (Check-ins)
      await _syncMedia();
      
      // Step 2: Push (Local -> Remote)
      final pushResult = await _pushChanges();
      
      // Step 3: Pull (Remote -> Local)
      await _pullChanges();
      
      return pushResult;
    } catch (e, stackTrace) {
      // Log error but don't throw - sync happens in background
      final errorType = _categorizeError(e);
      final errorMessage = _getErrorMessage(e, errorType);
      debugPrint('[SyncManager:Error] Category: $errorType, Message: $errorMessage');
      debugPrint('[SyncManager:Error] Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Step 1: Upload pending media (Check-in photos)
  Future<void> _syncMedia() async {
    final checkInsWithoutUrl = await _localDataSource.getCheckInsWithoutPhotoUrl();
    
    for (final checkIn in checkInsWithoutUrl) {
      try {
        // Check if we have a local photo path
        if (checkIn.photoLocalPath.isEmpty) {
          continue; // Skip if no local photo
        }
        
        // Read image bytes from local file
        Uint8List imageBytes;
        if (kIsWeb) {
          // Web implementation would need different approach
          continue;
        } else {
          final file = io.File(checkIn.photoLocalPath);
          if (!await file.exists()) {
            continue; // File doesn't exist, skip
          }
          imageBytes = await file.readAsBytes();
        }
        
        // Upload to Cloudinary
        final photoUrl = await _cloudinaryService.uploadCheckInPhoto(imageBytes);
        
        // Update check-in with photo URL
        checkIn.photoUrl = photoUrl;
        checkIn.isSynced = false; // Will be synced in push step
        await _localDataSource.saveCheckIn(checkIn);
      } catch (e) {
        // Continue with other check-ins
        debugPrint('Failed to upload check-in ${checkIn.id}: $e');
      }
    }
  }
  
  /// Step 2: Push dirty records to server
  Future<SyncResult> _pushChanges() async {
    final dirtyWorkouts = await _localDataSource.getDirtyWorkouts();
    final unsyncedCheckIns = await _localDataSource.getUnsyncedCheckIns();
    final dirtyPlans = await _localDataSource.getDirtyPlans();
    
    final totalCount = dirtyWorkouts.length + unsyncedCheckIns.length + dirtyPlans.length;
    
    if (totalCount == 0) {
      return SyncResult(successCount: 0, failedCount: 0, totalCount: 0, errors: []);
    }
    
    int successCount = 0;
    int failedCount = 0;
    final errors = <String>[];
    
    // Prepare batch data - convert workouts to API format
    final newLogs = <Map<String, dynamic>>[];
    for (final workout in dirtyWorkouts) {
      // Load exercises for workout
      final exercises = await _localDataSource.getExercisesForWorkout(workout.id);
      
      // Convert workout to API format
      // Note: WorkoutCollection doesn't have weeklyPlanId, dayOfWeek, etc.
      // These would need to be added to the model or extracted from workout name/date
      newLogs.add({
        'workoutDate': workout.scheduledDate.toIso8601String(),
        'weeklyPlanId': workout.serverId, // Use serverId as fallback
        'dayOfWeek': workout.scheduledDate.weekday,
        'completedExercises': exercises.map((e) => {
          'exerciseName': e.name,
          'actualSets': e.sets.length,
          'actualReps': e.sets.map((s) => s.reps).toList(),
          'weightUsed': e.sets.isNotEmpty ? e.sets.first.weight : 0,
        }).toList(),
        'isCompleted': workout.isCompleted,
        'completedAt': workout.isCompleted ? workout.updatedAt.toIso8601String() : null,
      });
    }
    
    // Prepare check-ins for API
    final newCheckIns = <Map<String, dynamic>>[];
    for (final checkIn in unsyncedCheckIns) {
      if (checkIn.photoUrl == null || checkIn.photoUrl!.isEmpty) {
        continue; // Skip if no photo URL
      }
      
      newCheckIns.add({
        'checkinDate': checkIn.timestamp.toIso8601String(),
        'photoUrl': checkIn.photoUrl,
        'gpsCoordinates': null, // CheckInCollection doesn't have GPS coordinates field
        'clientNotes': null, // CheckInCollection doesn't have notes field
      });
    }
    
    // Prepare plans for API
    final plansToPush = <Map<String, dynamic>>[];
    for (final plan in dirtyPlans) {
      try {
        final planEntity = PlanMapper.fromCollection(plan);
        final planDto = PlanMapper.toDto(planEntity);
        plansToPush.add(planDto);
      } catch (e) {
        debugPrint('Error converting plan ${plan.planId} to DTO: $e');
      }
    }
    
    if (newLogs.isEmpty && newCheckIns.isEmpty && plansToPush.isEmpty) {
      return SyncResult(successCount: 0, failedCount: 0, totalCount: 0, errors: []); // Nothing to sync
    }
    
    final batchData = {
      'syncedAt': DateTime.now().toIso8601String(),
      'newLogs': newLogs,
      'newCheckIns': newCheckIns,
      'plans': plansToPush,
    };
    
    try {
      // Use retry logic for sync batch
      await _retryWithBackoff(
        operation: () => _remoteDataSource.syncBatch(batchData),
        operationName: 'syncBatch',
        maxRetries: _maxPushRetries,
      );
      
      // Update local records based on server response
      // Mark as not dirty, update serverId if new, etc.
      for (final workout in dirtyWorkouts) {
        workout.isDirty = false;
        workout.updatedAt = DateTime.now();
        await _localDataSource.saveWorkout(workout);
        successCount++;
      }
      
      for (final checkIn in unsyncedCheckIns) {
        checkIn.isSynced = true;
        await _localDataSource.saveCheckIn(checkIn);
        successCount++;
      }
      
      // Mark plans as synced
      for (final plan in dirtyPlans) {
        plan.isDirty = false;
        plan.lastSync = DateTime.now();
        await _localDataSource.savePlan(plan);
        successCount++;
      }
      
      // Update last sync time in user collection
      final users = await _localDataSource.getUsers();
      if (users.isNotEmpty) {
        final user = users.first;
        user.lastSync = DateTime.now();
        await _localDataSource.saveUser(user);
      }
      
      debugPrint('[SyncManager:PartialSuccess] Synced: $successCount/$totalCount, Failed: $failedCount');
      
    } catch (e, stackTrace) {
      final errorType = _categorizeError(e);
      final errorMessage = _getErrorMessage(e, errorType);
      
      debugPrint('[SyncManager:Error] Category: $errorType, Message: $errorMessage');
      debugPrint('[SyncManager:Error] Stack trace: $stackTrace');
      
      failedCount = totalCount - successCount;
      errors.add(errorMessage);
      
      // Don't rethrow - allow partial success
      // On conflict (409), server wins - silently update local
      if (e is DioException && e.response?.statusCode == 409) {
        debugPrint('=== CONFLICT RESOLUTION STARTED ===');
        debugPrint('Conflict detected at ${DateTime.now().toIso8601String()}');
        debugPrint('Attempted to push: ${dirtyWorkouts.length} workouts, ${unsyncedCheckIns.length} check-ins');
        
        try {
          final responseData = e.response?.data;
          if (responseData != null) {
            if (responseData is Map<String, dynamic>) {
              final conflictWorkouts = responseData['workouts'] as List<dynamic>?;
              final conflictCheckIns = responseData['checkIns'] as List<dynamic>?;
              
              if (conflictWorkouts != null && conflictWorkouts.isNotEmpty) {
                debugPrint('Processing ${conflictWorkouts.length} conflicted workouts...');
                int processed = 0;
                for (final workoutData in conflictWorkouts) {
                  try {
                    final serverId = workoutData['_id']?.toString() ?? 'unknown';
                    final serverUpdated = workoutData['updatedAt'] != null
                        ? DateTime.parse(workoutData['updatedAt'] as String)
                        : DateTime.now();
                    
                    // Find local version for comparison
                    WorkoutCollection? localWorkout;
                    try {
                      localWorkout = dirtyWorkouts.firstWhere(
                        (w) => w.serverId == serverId,
                      );
                    } catch (_) {
                      // Not found in dirty workouts
                    }
                    
                    if (localWorkout != null) {
                      final timeDiff = serverUpdated.difference(localWorkout.updatedAt);
                      debugPrint('  - Workout $serverId: Server (${serverUpdated.toIso8601String()}) vs Local (${localWorkout.updatedAt.toIso8601String()}) - diff: ${timeDiff.inMinutes}min');
                    } else {
                      debugPrint('  - Workout $serverId: Server (${serverUpdated.toIso8601String()}) - new conflict');
                    }
                    
                    await _processServerWorkoutLog(workoutData as Map<String, dynamic>);
                    processed++;
                  } catch (workoutError) {
                    debugPrint('  - Failed to resolve conflict for workout ${workoutData['_id']}: $workoutError');
                  }
                }
                debugPrint('Resolved $processed/${conflictWorkouts.length} workout conflicts');
              }
              
              if (conflictCheckIns != null && conflictCheckIns.isNotEmpty) {
                debugPrint('Processing ${conflictCheckIns.length} conflicted check-ins...');
                int processed = 0;
                for (final checkInData in conflictCheckIns) {
                  try {
                    final serverId = checkInData['_id']?.toString() ?? 'unknown';
                    final serverDate = checkInData['checkinDate'] != null
                        ? DateTime.parse(checkInData['checkinDate'] as String)
                        : DateTime.now();
                    
                    debugPrint('  - Check-in $serverId: Server date ${serverDate.toIso8601String()}');
                    
                    await _processServerCheckIn(checkInData as Map<String, dynamic>);
                    processed++;
                  } catch (checkInError) {
                    debugPrint('  - Failed to resolve conflict for check-in ${checkInData['_id']}: $checkInError');
                  }
                }
                debugPrint('Resolved $processed/${conflictCheckIns.length} check-in conflicts');
              }
              
              // Process conflicted plans (server wins)
              final conflictPlans = responseData['plans'] as List<dynamic>?;
              if (conflictPlans != null && conflictPlans.isNotEmpty) {
                debugPrint('Processing ${conflictPlans.length} conflicted plans...');
                int processed = 0;
                for (final planData in conflictPlans) {
                  try {
                    await _processServerPlan(planData as Map<String, dynamic>);
                    processed++;
                  } catch (planError) {
                    debugPrint('  - Failed to resolve conflict for plan ${planData['_id']}: $planError');
                  }
                }
                debugPrint('Resolved $processed/${conflictPlans.length} plan conflicts');
              }
              
              final totalConflicts = (conflictWorkouts?.length ?? 0) + (conflictCheckIns?.length ?? 0) + (conflictPlans?.length ?? 0);
              debugPrint('=== CONFLICT RESOLUTION COMPLETED: $totalConflicts total conflicts resolved (Server Wins policy) ===');
            }
          }
        } catch (conflictError, stackTrace) {
          debugPrint('=== CONFLICT RESOLUTION ERROR ===');
          debugPrint('Error processing conflict resolution: $conflictError');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('Continuing sync despite conflict resolution failure');
        }
      } else {
        // Re-throw other errors
        failedCount = totalCount - successCount;
        final errorType = _categorizeError(e);
        final errorMessage = _getErrorMessage(e, errorType);
        errors.add(errorMessage);
        debugPrint('[SyncManager:Error] Category: $errorType, Message: $errorMessage');
      }
    }
    
    return SyncResult(
      successCount: successCount,
      failedCount: failedCount,
      totalCount: totalCount,
      errors: errors,
    );
  }

  // Helper method for future use (currently unused)
  // bool _isRetryableError(DioException error) { ... }

  /// Get human-readable error type string
  String _getErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection Timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive Timeout';
      case DioExceptionType.sendTimeout:
        return 'Send Timeout';
      case DioExceptionType.connectionError:
        return 'Connection Error';
      default:
        return 'HTTP ${error.response?.statusCode ?? 'Unknown'}';
    }
  }

  /// Step 3: Pull changes from server
  Future<void> _pullChanges() async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[SyncManager] _pullChanges() START');
    
    final users = await _localDataSource.getUsers();
    DateTime lastSync;
    
    if (users.isNotEmpty) {
      lastSync = users.first.lastSync;
      debugPrint('[SyncManager] → Last sync from user: ${lastSync.toIso8601String()}');
    } else {
      // Default to 7 days ago if no last sync
      lastSync = DateTime.now().subtract(const Duration(days: 7));
      debugPrint('[SyncManager] → No user found, using default: ${lastSync.toIso8601String()}');
    }
    
    try {
      debugPrint('[SyncManager] → Calling getSyncChanges API with since: ${lastSync.toIso8601String()}');
      
      // Wrap API call with retry mechanism
      final changes = await _retryWithBackoff(
        operation: () => _remoteDataSource.getSyncChanges(lastSync.toIso8601String()),
        operationName: 'getSyncChanges',
        maxRetries: _maxPullRetries,
      );
      
      debugPrint('[SyncManager] → API response received');
      debugPrint('[SyncManager] → Response keys: ${changes.keys.toList()}');
      
      final workouts = changes['workouts'] as List<dynamic>? ?? [];
      final checkIns = changes['checkIns'] as List<dynamic>? ?? [];
      final plans = changes['plans'] as List<dynamic>? ?? [];
      
      debugPrint('[SyncManager] → Parsed response:');
      debugPrint('[SyncManager]   - Workouts: ${workouts.length}');
      debugPrint('[SyncManager]   - CheckIns: ${checkIns.length}');
      debugPrint('[SyncManager]   - Plans: ${plans.length}');
      
      // Process workouts with individual error handling
      debugPrint('[SyncManager] → Processing workouts...');
      int processedWorkouts = 0;
      int failedWorkouts = 0;
      for (final workoutData in workouts) {
        try {
          await _processServerWorkoutLog(workoutData as Map<String, dynamic>);
          processedWorkouts++;
        } catch (e) {
          failedWorkouts++;
          debugPrint('[SyncManager] ✗ Failed to process workout: ${workoutData['_id']} - $e');
        }
      }
      debugPrint('[SyncManager] → Workouts processed: $processedWorkouts, failed: $failedWorkouts');
      
      // Process check-ins with individual error handling
      debugPrint('[SyncManager] → Processing check-ins...');
      int processedCheckIns = 0;
      int failedCheckIns = 0;
      for (final checkInData in checkIns) {
        try {
          await _processServerCheckIn(checkInData as Map<String, dynamic>);
          processedCheckIns++;
        } catch (e) {
          failedCheckIns++;
          debugPrint('[SyncManager] ✗ Failed to process check-in: ${checkInData['_id']} - $e');
        }
      }
      debugPrint('[SyncManager] → CheckIns processed: $processedCheckIns, failed: $failedCheckIns');
      
      // Process plans with individual error handling
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[SyncManager] PLAN PULL SYNC START');
      debugPrint('[SyncManager] → Plans received from server: ${plans.length}');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      int processedPlans = 0;
      int failedPlans = 0;
      for (final planData in plans) {
        try {
          final planId = planData['_id']?.toString() ?? 'unknown';
          debugPrint('[SyncManager] → Processing plan: $planId');
          await _processServerPlan(planData as Map<String, dynamic>);
          processedPlans++;
          debugPrint('[SyncManager] ✓ Plan processed: $planId');
        } catch (e, stackTrace) {
          failedPlans++;
          final planId = planData['_id']?.toString() ?? 'unknown';
          debugPrint('[SyncManager] ✗ Failed to process plan $planId: $e');
          debugPrint('[SyncManager] Stack trace: $stackTrace');
        }
      }
      
      // Log plan sync results
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('[SyncManager] PLAN PULL SYNC RESULTS');
      debugPrint('[SyncManager] → Processed: $processedPlans');
      debugPrint('[SyncManager] → Failed: $failedPlans');
      debugPrint('═══════════════════════════════════════════════════════════');
      
      // Update last sync time only if at least some data was processed
      if (processedWorkouts > 0 || processedCheckIns > 0 || processedPlans > 0) {
        if (users.isNotEmpty) {
          final user = users.first;
          user.lastSync = DateTime.now();
          await _localDataSource.saveUser(user);
        }
      }
      
      if (failedWorkouts > 0 || failedCheckIns > 0 || failedPlans > 0) {
        debugPrint('Pull sync completed with errors: $failedWorkouts workouts, $failedCheckIns check-ins, $failedPlans plans failed');
      } else {
        debugPrint('Pull sync completed successfully: $processedWorkouts workouts, $processedCheckIns check-ins, $processedPlans plans processed');
      }
      
    } on DioException catch (e) {
      // Detailed error logging based on error type
      final errorType = _getErrorType(e);
      debugPrint('Pull sync failed ($errorType): ${e.message}');
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}, body: ${e.response?.data}');
      }
    } catch (e, stackTrace) {
      debugPrint('Pull sync unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Process server workout log data and update/create local workout
  Future<void> _processServerWorkoutLog(Map<String, dynamic> workoutData) async {
    try {
      final serverId = workoutData['_id']?.toString() ?? '';
      if (serverId.isEmpty) {
        debugPrint('Skipping workout log without _id');
        return;
      }
      
      // Check if workout already exists locally
      final existingWorkout = await _localDataSource.getWorkoutByServerId(serverId);
      
      // Parse dates
      final workoutDate = DateTime.parse(workoutData['workoutDate'] as String);
      final updatedAt = workoutData['updatedAt'] != null
          ? DateTime.parse(workoutData['updatedAt'] as String)
          : DateTime.now();
      
      // Check if server version is newer (Server Wins policy)
      if (existingWorkout != null) {
        // If local is dirty and server is newer, server wins
        if (existingWorkout.isDirty && updatedAt.isAfter(existingWorkout.updatedAt)) {
          // Server wins - overwrite local
        } else if (existingWorkout.isDirty && updatedAt.isBefore(existingWorkout.updatedAt)) {
          // Local is newer and dirty, skip this update (local will push)
          return;
        }
      }
      
      // Get workout name from weeklyPlan or use default
      String workoutName = 'Workout';
      if (workoutData['weeklyPlanId'] != null) {
        final weeklyPlan = workoutData['weeklyPlanId'];
        if (weeklyPlan is Map && weeklyPlan['name'] != null) {
          workoutName = weeklyPlan['name'] as String;
        }
      }
      
      // Create/update workout collection
      final workout = existingWorkout ?? WorkoutCollection();
      workout.serverId = serverId;
      workout.name = workoutName;
      workout.scheduledDate = workoutDate;
      workout.isCompleted = workoutData['isCompleted'] as bool? ?? false;
      workout.isDirty = false; // Server data is source of truth
      workout.updatedAt = updatedAt;
      
      // Note: We need to handle exercises separately as they're stored as IsarLinks
      // For now, we'll save the workout and exercises will be handled separately
      // This is a limitation - we may need to refactor to store exercises differently
      
      await _localDataSource.saveWorkout(workout);
      
      // TODO: Process and save exercises from completedExercises array
      // This requires creating ExerciseCollection entries and linking them
      // For now, exercises will be synced when user opens the workout
      
    } catch (e) {
      debugPrint('Error processing server workout log: $e');
    }
  }
  
  /// Process server plan data and update/create local plan
  Future<void> _processServerPlan(Map<String, dynamic> planData) async {
    debugPrint('[SyncManager._processServerPlan] START');
    try {
      final serverId = planData['_id']?.toString() ?? '';
      debugPrint('[SyncManager._processServerPlan] → Server plan ID: $serverId');
      debugPrint('[SyncManager._processServerPlan] → Plan name: ${planData['name']}');
      
      if (serverId.isEmpty) {
        debugPrint('[SyncManager._processServerPlan] ✗ Skipping plan without _id');
        return;
      }
      
      // Check if plan exists locally
      debugPrint('[SyncManager._processServerPlan] → Checking if plan exists locally...');
      final existingPlan = await _localDataSource.getPlanById(serverId);
      
      if (existingPlan != null) {
        debugPrint('[SyncManager._processServerPlan] → Plan exists locally (Isar ID: ${existingPlan.id})');
        debugPrint('[SyncManager._processServerPlan] → Local isDirty: ${existingPlan.isDirty}');
        debugPrint('[SyncManager._processServerPlan] → Local updatedAt: ${existingPlan.updatedAt}');
      } else {
        debugPrint('[SyncManager._processServerPlan] → Plan does not exist locally - will create new');
      }
      
      // Parse dates
      final updatedAt = planData['updatedAt'] != null
          ? DateTime.parse(planData['updatedAt'] as String)
          : DateTime.now();
      debugPrint('[SyncManager._processServerPlan] → Server updatedAt: $updatedAt');
      
      // Server Wins policy (ako lokalni postoji i nije dirty, ili ako server je noviji)
      if (existingPlan != null) {
        if (existingPlan.isDirty && updatedAt.isBefore(existingPlan.updatedAt)) {
          // Local is newer and dirty, skip this update (local will push)
          debugPrint('[SyncManager._processServerPlan] ⚠ Skipping - local version is newer and dirty');
          debugPrint('[SyncManager._processServerPlan] → Local will be pushed instead');
          return;
        }
        debugPrint('[SyncManager._processServerPlan] → Server wins - will overwrite local');
      }
      
      // Convert DTO to Entity to Collection
      debugPrint('[SyncManager._processServerPlan] → Converting DTO to Entity...');
      final planEntity = PlanMapper.toEntity(planData);
      debugPrint('[SyncManager._processServerPlan] → Converting Entity to Collection...');
      final planCollection = PlanMapper.toCollection(planEntity);
      
      if (existingPlan != null) {
        planCollection.id = existingPlan.id;
        planCollection.isDirty = false; // Server overwrites local
        debugPrint('[SyncManager._processServerPlan] → Preserving local Isar ID: ${planCollection.id}');
      }
      
      planCollection.lastSync = DateTime.now();
      debugPrint('[SyncManager._processServerPlan] → Saving to local database...');
      await _localDataSource.savePlan(planCollection);
      
      debugPrint('[SyncManager._processServerPlan] ✓ Processed plan: ${planCollection.name} (Server ID: $serverId)');
      
    } catch (e, stackTrace) {
      debugPrint('[SyncManager._processServerPlan] ✗✗✗ ERROR processing server plan: $e');
      debugPrint('[SyncManager._processServerPlan] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Process server check-in data and update/create local check-in
  Future<void> _processServerCheckIn(Map<String, dynamic> checkInData) async {
    try {
      final serverId = checkInData['_id']?.toString();
      if (serverId == null || serverId.isEmpty) {
        debugPrint('Skipping check-in without _id');
        return;
      }
      
      // Parse dates
      final checkInDate = DateTime.parse(checkInData['checkinDate'] as String);
      final photoUrl = checkInData['photoUrl'] as String? ?? '';
      
      if (photoUrl.isEmpty) {
        debugPrint('Skipping check-in without photoUrl');
        return;
      }
      
      // Get all check-ins to find if this one exists locally (by date and photoUrl)
      final allCheckIns = await _localDataSource.getAllCheckIns();
      
      CheckInCollection? existingCheckIn;
      for (final ci in allCheckIns) {
        final ciDate = DateTime(ci.timestamp.year, ci.timestamp.month, ci.timestamp.day);
        final serverDate = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
        if (ciDate == serverDate && ci.photoUrl == photoUrl) {
          existingCheckIn = ci;
          break;
        }
      }
      
      CheckInCollection checkIn;
      if (existingCheckIn != null) {
        // Update existing check-in
        checkIn = existingCheckIn;
        checkIn.photoUrl = photoUrl;
        checkIn.isSynced = true;
      } else {
        // Create new check-in
        checkIn = CheckInCollection()
          ..photoLocalPath = '' // Server check-in, no local path
          ..photoUrl = photoUrl
          ..timestamp = checkInDate
          ..isSynced = true;
      }
      
      await _localDataSource.saveCheckIn(checkIn);
      
    } catch (e) {
      debugPrint('Error processing server check-in: $e');
    }
  }
}
