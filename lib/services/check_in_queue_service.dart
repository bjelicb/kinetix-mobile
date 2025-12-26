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

  /// Upload queued check-ins when connection returns
  /// Processes all unsynced check-ins (isSynced = false) from offline mode
  /// Flow: 1. Upload photo to Cloudinary 2. Create check-in on server 3. Mark as synced
  /// Called automatically by SyncManager when sync() is executed
  Future<void> syncQueuedCheckIns() async {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[CheckInQueue:Sync] ═══════ QUEUED CHECK-INS SYNC START ═══════');
    debugPrint('[CheckInQueue:Sync] Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');

    try {
      debugPrint('[CheckInQueue:Sync] 📋 Fetching unsynced check-ins from local database...');
      final queued = await _localDataSource.getUnsyncedCheckIns();

      if (queued.isEmpty) {
        debugPrint('[CheckInQueue:Sync] ✅ No queued check-ins to sync');
        debugPrint('[CheckInQueue:Sync] ═══════ QUEUED CHECK-INS SYNC COMPLETE ═══════');
        debugPrint('═══════════════════════════════════════════════════════════');
        return;
      }

      debugPrint('[CheckInQueue:Sync] 📦 Found ${queued.length} queued check-in(s) to sync');
      debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');

      int successCount = 0;
      int failedCount = 0;

      for (int i = 0; i < queued.length; i++) {
        final checkIn = queued[i];
        try {
          debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');
          debugPrint('[CheckInQueue:Sync] 📤 Processing check-in ${i + 1}/${queued.length}');
          debugPrint('[CheckInQueue:Sync] Check-in ID: ${checkIn.id}');
          debugPrint('[CheckInQueue:Sync] Timestamp: ${checkIn.timestamp}');
          debugPrint('[CheckInQueue:Sync] Photo path: ${checkIn.photoLocalPath}');
          debugPrint('[CheckInQueue:Sync] Current photoUrl: ${checkIn.photoUrl ?? "NULL"}');

          // Upload photo to Cloudinary if not already uploaded
          String? photoUrl = checkIn.photoUrl;

          if (photoUrl == null && checkIn.photoLocalPath.isNotEmpty) {
            debugPrint('[CheckInQueue:Sync] 📸 Uploading photo to Cloudinary...');
            debugPrint('[CheckInQueue:Sync] Photo path: ${checkIn.photoLocalPath}');
            photoUrl = await _cloudinaryService.uploadCheckInPhotoFromPath(checkIn.photoLocalPath);
            debugPrint('[CheckInQueue:Sync] ✅ Photo uploaded successfully');
            debugPrint('[CheckInQueue:Sync] Photo URL: $photoUrl');
          } else if (photoUrl != null) {
            debugPrint('[CheckInQueue:Sync] ℹ️ Photo already uploaded (URL exists)');
          } else {
            debugPrint('[CheckInQueue:Sync] ⚠️ No photo path available - skipping upload');
          }

          // Create check-in on server
          final checkInData = {
            'checkinDate': checkIn.timestamp.toIso8601String(),
            'photoUrl': photoUrl,
            'gpsCoordinates': checkIn.latitude != null && checkIn.longitude != null
                ? {'latitude': checkIn.latitude, 'longitude': checkIn.longitude}
                : null,
          };

          debugPrint('[CheckInQueue:Sync] 📡 Creating check-in on server...');
          debugPrint('[CheckInQueue:Sync] Request data:');
          debugPrint('[CheckInQueue:Sync]   - checkinDate: ${checkInData['checkinDate']}');
          debugPrint('[CheckInQueue:Sync]   - photoUrl: ${photoUrl != null ? "PROVIDED" : "NULL"}');
          debugPrint(
            '[CheckInQueue:Sync]   - gpsCoordinates: ${checkInData['gpsCoordinates'] != null ? "PROVIDED" : "NULL"}',
          );

          debugPrint('[CheckInQueue:Sync] 📡 Sending POST /checkins request to backend...');
          await _remoteDataSource.createCheckIn(checkInData);
          debugPrint('[CheckInQueue:Sync] ✅ Server check-in creation SUCCESS');
          debugPrint('[CheckInQueue:Sync] → Backend should have received and saved check-in to MongoDB');

          // Update local check-in as synced
          checkIn.isSynced = true;
          checkIn.photoUrl = photoUrl;
          await _localDataSource.saveCheckIn(checkIn);

          successCount++;
          debugPrint('[CheckInQueue:Sync] ✅ Check-in ${checkIn.id} synced successfully');
          debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');
        } catch (e, stackTrace) {
          failedCount++;
          debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');
          debugPrint('[CheckInQueue:Sync] ❌ ERROR uploading check-in ${checkIn.id}');
          debugPrint('[CheckInQueue:Sync] Error: $e');
          debugPrint('[CheckInQueue:Sync] Error type: ${e.runtimeType}');
          debugPrint('[CheckInQueue:Sync] Stack trace: $stackTrace');
          debugPrint('[CheckInQueue:Sync] → Will retry on next sync');
          debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');
          // Continue with next check-in
        }
      }

      debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');
      debugPrint('[CheckInQueue:Sync] 📊 SYNC SUMMARY');
      debugPrint('[CheckInQueue:Sync] Total queued: ${queued.length}');
      debugPrint('[CheckInQueue:Sync] ✅ Successful: $successCount');
      debugPrint('[CheckInQueue:Sync] ❌ Failed: $failedCount');
      debugPrint('[CheckInQueue:Sync] ═══════ QUEUED CHECK-INS SYNC COMPLETE ═══════');
      debugPrint('═══════════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('[CheckInQueue:Sync] ════════════════════════════════════════');
      debugPrint('[CheckInQueue:Sync] ❌ FATAL ERROR during sync');
      debugPrint('[CheckInQueue:Sync] Error: $e');
      debugPrint('[CheckInQueue:Sync] Error type: ${e.runtimeType}');
      debugPrint('[CheckInQueue:Sync] Stack trace: $stackTrace');
      debugPrint('[CheckInQueue:Sync] ═══════ QUEUED CHECK-INS SYNC FAILED ═══════');
      debugPrint('═══════════════════════════════════════════════════════════');
      rethrow;
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
        final checkInDate = DateTime(checkIn.timestamp.year, checkIn.timestamp.month, checkIn.timestamp.day);

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
