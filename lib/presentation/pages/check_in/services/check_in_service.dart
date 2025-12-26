import 'dart:io' as io show File;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../data/datasources/local_data_source.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../../data/models/checkin_collection.dart'
    if (dart.library.html) '../../../../data/models/checkin_collection_stub.dart';
import '../../../../services/cloudinary_upload_service.dart';
import '../../../../core/utils/shared_preferences_service.dart';
import '../../../../core/constants/api_constants.dart';
import 'check_in_validation_service.dart';
import 'image_compression_service.dart';
import 'location_service.dart';

/// Save check-in result
class CheckInSaveResult {
  final bool success;
  final String? warningMessage;

  CheckInSaveResult({required this.success, this.warningMessage});
}

/// Service for check-in business logic
class CheckInService {
  /// Quick connectivity check - attempts a fast HEAD request to backend
  /// Returns true if connection is available, false otherwise
  static Future<bool> _checkConnectivity() async {
    try {
      debugPrint('[CheckInService] 🔍 Checking connectivity...');
      final dio = Dio();
      dio.options.baseUrl = ApiConstants.baseUrl;
      dio.options.connectTimeout = Duration(seconds: 3); // Fast timeout for connectivity check
      dio.options.receiveTimeout = Duration(seconds: 3);
      
      // Try a lightweight HEAD request to backend health endpoint or auth/me
      await dio.head('/auth/me');
      debugPrint('[CheckInService] ✅ Connectivity check PASSED');
      return true;
    } catch (e) {
      debugPrint('[CheckInService] 📴 Connectivity check FAILED: $e');
      return false;
    }
  }

  /// Save check-in with full orchestration
  /// 
  /// OFFLINE MODE FLOW:
  /// 1. Connectivity check (3s timeout) - detects if backend is reachable
  /// 2. If NO connection: Check-in is queued immediately (isSynced = false)
  ///    - Photo saved locally
  ///    - Check-in saved to Isar with isSynced = false
  ///    - markCheckInFulfilled() called - user can continue with workout
  /// 3. When connection returns: SyncManager.sync() → CheckInQueueService.syncQueuedCheckIns()
  ///    - Uploads photo to Cloudinary
  ///    - Creates check-in on server via API
  ///    - Marks as synced (isSynced = true)
  /// 
  /// ONLINE MODE FLOW:
  /// 1. Connectivity check passes
  /// 2. Upload photo to Cloudinary
  /// 3. Create check-in on server via API
  /// 4. Save locally with isSynced = true
  /// 5. markCheckInFulfilled() called
  /// 
  /// Returns result with success status and optional warning
  static Future<CheckInSaveResult> saveCheckIn(XFile capturedImage) async {
    try {
      debugPrint('[CheckInService] ═══════════════════════════════════════');
      debugPrint('[CheckInService] saveCheckIn() START');
      debugPrint('[CheckInService] Photo path: ${capturedImage.path}');
      debugPrint('[CheckInService] Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      // Read image bytes
      debugPrint('[CheckInService] Reading image bytes...');
      Uint8List imageBytes;
      if (!kIsWeb) {
        imageBytes = await io.File(capturedImage.path).readAsBytes();
      } else {
        imageBytes = await capturedImage.readAsBytes();
      }
      final originalSize = imageBytes.lengthInBytes;
      debugPrint('[CheckInService] Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

      // Validate check-in date vs workout date
      debugPrint('[CheckInService] Validating check-in date...');
      final localDataSource = LocalDataSource();
      final todayWorkouts = await localDataSource.getTodayWorkouts();
      final checkInDate = DateTime.now();
      debugPrint('[CheckInService] Check-in date: $checkInDate');
      debugPrint('[CheckInService] Today workouts count: ${todayWorkouts.length}');

      String? validationWarning;
      if (todayWorkouts.isNotEmpty) {
        final workoutDate = todayWorkouts.first.scheduledDate;
        debugPrint('[CheckInService] Workout scheduled date: $workoutDate');
        final validation = CheckInValidationService.validateCheckInDate(checkInDate, workoutDate);

        if (!validation.isValid && validation.warningMessage != null) {
          validationWarning = validation.warningMessage;
          debugPrint('[CheckInService] ⚠️ Validation warning: $validationWarning');
          // Continue with check-in despite warning
        } else {
          debugPrint('[CheckInService] ✅ Validation passed');
        }
      } else {
        debugPrint('[CheckInService] No workouts scheduled for today');
      }

      // Compress and resize image
      debugPrint('[CheckInService] Compressing image...');
      final compressedBytes = await ImageCompressionService.compressAndResizeImage(imageBytes);
      final compressedSize = compressedBytes.lengthInBytes;
      final compressionRatio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      debugPrint('[CheckInService] ✅ Image compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('[CheckInService] Compression ratio: $compressionRatio% reduction');

      // Save compressed image locally (skip on web)
      String? savedPath;
      if (!kIsWeb) {
        debugPrint('[CheckInService] Saving compressed image locally...');
        savedPath = await ImageCompressionService.saveCompressedImageLocally(compressedBytes);
        debugPrint('[CheckInService] ✅ Image saved locally: $savedPath');
      } else {
        debugPrint('[CheckInService] Web platform - skipping local save');
      }

      // Get GPS location
      debugPrint('[CheckInService] Requesting GPS location...');
      final gpsCoordinates = await LocationService.getCurrentLocation();
      if (gpsCoordinates != null) {
        debugPrint('[CheckInService] ✅ GPS location obtained: ${gpsCoordinates['latitude']}, ${gpsCoordinates['longitude']}');
      } else {
        debugPrint('[CheckInService] ⚠️ GPS location not available (will continue without GPS)');
      }

      // Upload to Cloudinary and create check-in
      String? photoUrl;
      bool uploadSuccess = false;
      
      // Step 1: Quick connectivity check before attempting upload
      debugPrint('[CheckInService] ═══════════════════════════════════════');
      debugPrint('[CheckInService] 🔍 Pre-upload connectivity check...');
      final hasConnection = await _checkConnectivity();
      
      if (!hasConnection) {
        debugPrint('[CheckInService] 📴 FULL OFFLINE MODE DETECTED - No connection to backend');
        debugPrint('[CheckInService] → Check-in will be QUEUED locally (isSynced = false)');
        debugPrint('[CheckInService] → User can continue with workout');
        debugPrint('[CheckInService] → When connection returns, sync will upload photo and create on server');
        uploadSuccess = false;
      } else {
        // Step 2: Attempt upload only if connectivity is available
        try {
          debugPrint('[CheckInService] ═══════════════════════════════════════');
          debugPrint('[CheckInService] 🌐 ONLINE MODE - Attempting Cloudinary upload...');
          debugPrint('[CheckInService] ═══════════════════════════════════════');
          
          final storage = FlutterSecureStorage();
          final dio = Dio();
          // Reduced timeout for check-in operations (10s instead of 30s)
          dio.options.baseUrl = ApiConstants.baseUrl;
          dio.options.connectTimeout = Duration(seconds: 10);
          dio.options.receiveTimeout = Duration(seconds: 10);
          final remoteDataSource = RemoteDataSource(dio, storage);
          final cloudinaryService = CloudinaryUploadService(remoteDataSource);

          // Upload to Cloudinary
          debugPrint('[CheckInService] Uploading to Cloudinary...');
          photoUrl = await cloudinaryService.uploadCheckInPhoto(compressedBytes);
          debugPrint('[CheckInService] ✅ Cloudinary upload SUCCESS');
          debugPrint('[CheckInService] Photo URL: $photoUrl');

          // Create check-in via API
          final checkInData = {
            'checkinDate': DateTime.now().toIso8601String(),
            'photoUrl': photoUrl,
            'gpsCoordinates': gpsCoordinates,
          };
          
          debugPrint('[CheckInService] ═══════════════════════════════════════');
          debugPrint('[CheckInService] Preparing API request...');
          debugPrint('[CheckInService] Request body:');
          debugPrint('[CheckInService]   - checkinDate: ${checkInData['checkinDate']}');
          debugPrint('[CheckInService]   - photoUrl: PROVIDED (${photoUrl.length} chars)');
          debugPrint('[CheckInService]   - gpsCoordinates: ${gpsCoordinates != null ? 'lat=${gpsCoordinates['latitude']}, lon=${gpsCoordinates['longitude']}' : 'NULL'}');
          debugPrint('[CheckInService] ═══════════════════════════════════════');
          
          await remoteDataSource.createCheckIn(checkInData);
          debugPrint('[CheckInService] ✅ API check-in creation SUCCESS');
          uploadSuccess = true;
          debugPrint('[CheckInService] ✅ ONLINE MODE - Check-in uploaded successfully');
        } catch (uploadError, stackTrace) {
          // If upload fails, queue for later sync (OFFLINE MODE)
          final isNetworkError = uploadError is DioException &&
              (uploadError.type == DioExceptionType.connectionTimeout ||
                  uploadError.type == DioExceptionType.connectionError ||
                  uploadError.type == DioExceptionType.receiveTimeout ||
                  uploadError.type == DioExceptionType.sendTimeout);
          
          debugPrint('[CheckInService] ═══════════════════════════════════════');
          if (isNetworkError) {
            debugPrint('[CheckInService] 📴 NETWORK ERROR DETECTED');
            debugPrint('[CheckInService] Error type: ${uploadError.type}');
            debugPrint('[CheckInService] → Network timeout/connection error - Queueing for sync');
          } else {
            debugPrint('[CheckInService] ⚠️ SERVER ERROR DETECTED');
            debugPrint('[CheckInService] Error type: ${uploadError.runtimeType}');
            debugPrint('[CheckInService] Status code: ${(uploadError as DioException).response?.statusCode ?? "N/A"}');
            debugPrint('[CheckInService] → Server error - Queueing for sync');
          }
          debugPrint('[CheckInService] Error details: $uploadError');
          debugPrint('[CheckInService] Stack trace: $stackTrace');
          debugPrint('[CheckInService] → Check-in will be QUEUED locally for sync when internet returns');
          debugPrint('[CheckInService] ═══════════════════════════════════════');
          uploadSuccess = false;
        }
      }

      // Save to Isar database (skip on web)
      if (!kIsWeb && savedPath != null) {
        debugPrint('[CheckInService] ═══════════════════════════════════════');
        debugPrint('[CheckInService] Saving to Isar database...');
        final checkIn = CheckInCollection()
          ..photoLocalPath = savedPath
          ..photoUrl = photoUrl
          ..timestamp = DateTime.now()
          ..isSynced = uploadSuccess // Mark as synced only if upload succeeded
          ..latitude = gpsCoordinates?['latitude']
          ..longitude = gpsCoordinates?['longitude'];

        debugPrint('[CheckInService] Check-in object created:');
        debugPrint('[CheckInService]   - photoLocalPath: $savedPath');
        debugPrint('[CheckInService]   - photoUrl: ${photoUrl ?? "NULL (will upload later)"}');
        debugPrint('[CheckInService]   - timestamp: ${checkIn.timestamp}');
        debugPrint('[CheckInService]   - isSynced: ${checkIn.isSynced} (${uploadSuccess ? "ONLINE" : "OFFLINE - QUEUED"})');
        debugPrint('[CheckInService]   - latitude: ${checkIn.latitude}');
        debugPrint('[CheckInService]   - longitude: ${checkIn.longitude}');
        
        await localDataSource.saveCheckIn(checkIn);
        debugPrint('[CheckInService] ✅ Isar database save SUCCESS - ID: ${checkIn.id}');
        
        // Validate that check-in was queued successfully (if offline)
        // OFFLINE FLOW: Check-in is saved locally with isSynced = false
        // When connection returns, SyncManager.sync() will call CheckInQueueService.syncQueuedCheckIns()
        // which will upload the photo and create check-in on server
        if (!uploadSuccess) {
          // Double-check that check-in is actually queued (isSynced = false)
          final savedCheckIn = await localDataSource.getCheckInById(checkIn.id);
          if (savedCheckIn != null && savedCheckIn.isSynced == false) {
            debugPrint('[CheckInService] ═══════════════════════════════════════');
            debugPrint('[CheckInService] ✅ OFFLINE CHECK-IN QUEUED (VALIDATED)');
            debugPrint('[CheckInService] → Check-in ID: ${checkIn.id}');
            debugPrint('[CheckInService] → Photo path: $savedPath (saved locally)');
            debugPrint('[CheckInService] → isSynced: false ✓ (confirmed - will sync when connection returns)');
            debugPrint('[CheckInService] ⚠️ VAŽNO: Sync se NE poziva automatski kada se konekcija vrati!');
            debugPrint('[CheckInService] → Korisnik mora da uradi MANUAL SYNC (Settings → Manual Sync)');
            debugPrint('[CheckInService] → ILI: Logout i Login ponovo (sync se poziva pri login-u)');
            debugPrint('[CheckInService] → Flow: Manual sync → Upload photo → Create on server → Mark as synced');
            debugPrint('[CheckInService] ═══════════════════════════════════════');
          } else {
            debugPrint('[CheckInService] ⚠️ WARNING: Check-in may not be properly queued');
            debugPrint('[CheckInService] → Saved check-in isSynced: ${savedCheckIn?.isSynced}');
            // Force re-save with isSynced = false to ensure queue
            checkIn.isSynced = false;
            await localDataSource.saveCheckIn(checkIn);
            debugPrint('[CheckInService] → Re-saved with isSynced = false to ensure queue');
            debugPrint('[CheckInService] ✅ Check-in queue validated and corrected');
          }
        }
      } else {
        if (kIsWeb) {
          debugPrint('[CheckInService] Web platform - skipping Isar save');
        } else {
          debugPrint('[CheckInService] ⚠️ No saved path - skipping Isar save');
        }
      }

      // Mark check-in requirement as fulfilled for this session
      // This allows user to continue with workout even in offline mode
      // The queued check-in will be synced when connection returns
      await SharedPreferencesService.markCheckInFulfilled();
      
      debugPrint('[CheckInService] ═══════════════════════════════════════');
      debugPrint('[CheckInService] ✅ CHECK-IN PROCESS COMPLETED');
      if (!uploadSuccess) {
        debugPrint('[CheckInService] → Status: QUEUED (offline mode)');
        debugPrint('[CheckInService] → User can continue with workout');
        debugPrint('[CheckInService] → Check-in will sync when connection returns');
      } else {
        debugPrint('[CheckInService] → Status: SYNCED (online mode)');
      }
      debugPrint('[CheckInService] ═══════════════════════════════════════');
      
      return CheckInSaveResult(
        success: true,
        warningMessage: validationWarning,
      );
    } catch (e, stackTrace) {
      debugPrint('[CheckInService] ❌ FATAL ERROR saving check-in: $e');
      debugPrint('[CheckInService] Error type: ${e.runtimeType}');
      debugPrint('[CheckInService] Stack trace: $stackTrace');
      debugPrint('[CheckInService] ═══════════════════════════════════════');
      return CheckInSaveResult(success: false);
    }
  }
}

