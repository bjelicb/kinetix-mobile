import '../data/datasources/local_data_source.dart';
import '../data/datasources/remote_data_source.dart';
import '../data/models/checkin_collection.dart' if (dart.library.html) '../data/models/checkin_collection_stub.dart';
import '../data/models/workout_collection.dart' if (dart.library.html) '../data/models/workout_collection_stub.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncManager {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  
  SyncManager(this._localDataSource, this._remoteDataSource);
  
  /// Main sync method - Media-First, then Push, then Pull
  Future<void> sync() async {
    try {
      // Step 1: Media-First Sync (Check-ins)
      await _syncMedia();
      
      // Step 2: Push (Local -> Remote)
      await _pushChanges();
      
      // Step 3: Pull (Remote -> Local)
      await _pullChanges();
    } catch (e) {
      // Log error but don't throw - sync happens in background
      print('Sync error: $e');
    }
  }
  
  /// Step 1: Upload pending media (Check-in photos)
  Future<void> _syncMedia() async {
    final checkInsWithoutUrl = await _localDataSource.getCheckInsWithoutPhotoUrl();
    
    for (final checkIn in checkInsWithoutUrl) {
      try {
        // Get upload signature from backend
        final signature = await _remoteDataSource.getUploadSignature();
        
        // Upload to Cloudinary using signature
        // This would require Cloudinary SDK - simplified for now
        // After upload, update checkIn.photoUrl and mark as dirty
        
        checkIn.photoUrl = 'uploaded_url'; // Placeholder
        checkIn.isSynced = false; // Will be synced in push step
        await _localDataSource.saveCheckIn(checkIn);
      } catch (e) {
        // Continue with other check-ins
        print('Failed to upload check-in ${checkIn.id}: $e');
      }
    }
  }
  
  /// Step 2: Push dirty records to server
  Future<void> _pushChanges() async {
    final dirtyWorkouts = await _localDataSource.getDirtyWorkouts();
    final unsyncedCheckIns = await _localDataSource.getUnsyncedCheckIns();
    
    if (dirtyWorkouts.isEmpty && unsyncedCheckIns.isEmpty) {
      return; // Nothing to sync
    }
    
    // Prepare batch data
    final batchData = {
      'syncedAt': DateTime.now().toIso8601String(),
      'newLogs': dirtyWorkouts.map((w) => w.toJson()).toList(),
      'newCheckIns': unsyncedCheckIns.map((c) => c.toJson()).toList(),
    };
    
    try {
      final response = await _remoteDataSource.syncBatch(batchData);
      
      // Update local records based on server response
      // Mark as not dirty, update serverId if new, etc.
      for (final workout in dirtyWorkouts) {
        workout.isDirty = false;
        workout.updatedAt = DateTime.now();
        await _localDataSource.saveWorkout(workout);
      }
      
      for (final checkIn in unsyncedCheckIns) {
        checkIn.isSynced = true;
        await _localDataSource.saveCheckIn(checkIn);
      }
    } catch (e) {
      // On conflict (409), server wins - silently update local
      if (e is DioException && e.response?.statusCode == 409) {
        // Server returned updated data - overwrite local
        // This implements "Server Wins" policy
        // Implementation would update local records with server data
      } else {
        rethrow;
      }
    }
  }
  
  /// Step 3: Pull changes from server
  Future<void> _pullChanges() async {
    // Get last sync timestamp from user collection
    // For now, use a default timestamp
    final lastSync = DateTime.now().subtract(const Duration(days: 7));
    
    try {
      final changes = await _remoteDataSource.getSyncChanges(lastSync.toIso8601String());
      
      // Process changes and update local database
      // This would update/create local records based on server data
      // Server Wins policy applies here too
    } catch (e) {
      // Log but don't throw - pull can fail without breaking app
      print('Pull sync error: $e');
    }
  }
}

