import 'package:flutter/foundation.dart' show debugPrint;
import '../data/datasources/local_data_source.dart';
import '../data/datasources/remote_data_source.dart';
import '../data/models/checkin_collection.dart' if (dart.library.html) '../data/models/checkin_collection_stub.dart';
import '../services/cloudinary_upload_service.dart';

/// Service for managing check-in queue when offline
/// Handles saving check-ins locally and syncing when connection returns
class CheckInQueueService {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  late final CloudinaryUploadService _cloudinaryService;
  
  CheckInQueueService(this._localDataSource, this._remoteDataSource) {
    _cloudinaryService = CloudinaryUploadService(_remoteDataSource);
  }
  
  /// Save check-in locally when offline
  /// Stores photo and metadata for later upload
  Future<void> queueCheckIn(CheckInCollection checkIn) async {
    debugPrint('[CheckInQueue:Save] Check-in queued locally - ID: ${checkIn.id}');
    
    try {
      // Mark as not synced
      checkIn.isSynced = false;
      
      // Save to local database
      await _localDataSource.saveCheckIn(checkIn);
      
      debugPrint('[CheckInQueue:Save] Check-in saved successfully - Path: ${checkIn.photoLocalPath}');
    } catch (e, stackTrace) {
      debugPrint('[CheckInQueue:Save] ERROR saving check-in: $e');
      debugPrint('[CheckInQueue:Save] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Upload queued check-ins when online
  /// Processes all unsynced check-ins and uploads them
  Future<void> syncQueuedCheckIns() async {
    try {
      final queued = await _localDataSource.getUnsyncedCheckIns();
      
      if (queued.isEmpty) {
        debugPrint('[CheckInQueue:Sync] No queued check-ins to sync');
        return;
      }
      
      debugPrint('[CheckInQueue:Sync] Syncing ${queued.length} queued check-ins');
      
      for (final checkIn in queued) {
        try {
          debugPrint('[CheckInQueue:Sync] Processing check-in ${checkIn.id}');
          
          // Upload photo to Cloudinary if not already uploaded
          String? photoUrl = checkIn.photoUrl;
          
          if (photoUrl == null && checkIn.photoLocalPath.isNotEmpty) {
            debugPrint('[CheckInQueue:Sync] Uploading photo from ${checkIn.photoLocalPath}');
            photoUrl = await _cloudinaryService.uploadCheckInPhotoFromPath(checkIn.photoLocalPath);
            debugPrint('[CheckInQueue:Sync] Photo uploaded - URL: $photoUrl');
          }
          
          // Create check-in on server
          final checkInData = {
            'photoUrl': photoUrl,
            'timestamp': checkIn.timestamp.toIso8601String(),
          };
          
          await _remoteDataSource.createCheckIn(checkInData);
          
          // Update local check-in as synced
          checkIn.isSynced = true;
          checkIn.photoUrl = photoUrl;
          await _localDataSource.saveCheckIn(checkIn);
          
          debugPrint('[CheckInQueue:Sync] Check-in ${checkIn.id} uploaded successfully');
          
        } catch (e, stackTrace) {
          debugPrint('[CheckInQueue:Sync] ERROR uploading check-in ${checkIn.id}: $e');
          debugPrint('[CheckInQueue:Sync] Stack trace: $stackTrace');
          // Continue with next check-in
        }
      }
      
      debugPrint('[CheckInQueue:Sync] Sync completed');
      
    } catch (e, stackTrace) {
      debugPrint('[CheckInQueue:Sync] ERROR during sync: $e');
      debugPrint('[CheckInQueue:Sync] Stack trace: $stackTrace');
    }
  }
  
  /// Check if there's a queued check-in for today
  /// Used to bypass check-in requirement when offline
  Future<bool> hasQueuedCheckInForToday() async {
    try {
      final queued = await _localDataSource.getUnsyncedCheckIns();
      
      if (queued.isEmpty) return false;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if any queued check-in is from today
      for (final checkIn in queued) {
        final checkInDate = DateTime(
          checkIn.timestamp.year,
          checkIn.timestamp.month,
          checkIn.timestamp.day,
        );
        
        if (checkInDate.isAtSameMomentAs(today)) {
          debugPrint('[CheckInQueue:HasToday] Found queued check-in for today - ID: ${checkIn.id}');
          return true;
        }
      }
      
      return false;
      
    } catch (e) {
      debugPrint('[CheckInQueue:HasToday] ERROR checking queued check-ins: $e');
      return false;
    }
  }
  
  /// Get count of queued (unsynced) check-ins
  Future<int> getQueuedCount() async {
    try {
      final queued = await _localDataSource.getUnsyncedCheckIns();
      return queued.length;
    } catch (e) {
      debugPrint('[CheckInQueue:Count] ERROR getting queued count: $e');
      return 0;
    }
  }
}

