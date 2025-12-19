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
  /// Save check-in with full orchestration
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
      try {
        debugPrint('[CheckInService] Initializing Cloudinary upload...');
        final storage = FlutterSecureStorage();
        final dio = Dio();
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
        debugPrint('[CheckInService]   - photoUrl: ${photoUrl != null ? 'PROVIDED (${photoUrl.length} chars)' : 'NULL'}');
        debugPrint('[CheckInService]   - gpsCoordinates: ${gpsCoordinates != null ? 'lat=${gpsCoordinates['latitude']}, lon=${gpsCoordinates['longitude']}' : 'NULL'}');
        debugPrint('[CheckInService] ═══════════════════════════════════════');
        
        await remoteDataSource.createCheckIn(checkInData);
        debugPrint('[CheckInService] ✅ API check-in creation SUCCESS');
      } catch (uploadError, stackTrace) {
        // If upload fails, still save locally for later sync
        debugPrint('[CheckInService] ❌ Cloudinary/API error: $uploadError');
        debugPrint('[CheckInService] Error type: ${uploadError.runtimeType}');
        debugPrint('[CheckInService] Stack trace: $stackTrace');
        debugPrint('[CheckInService] Check-in will be saved locally for later sync');
      }

      // Save to Isar database (skip on web)
      if (!kIsWeb && savedPath != null) {
        debugPrint('[CheckInService] Saving to Isar database...');
        final checkIn = CheckInCollection()
          ..photoLocalPath = savedPath
          ..photoUrl = photoUrl
          ..timestamp = DateTime.now()
          ..isSynced = photoUrl != null // Mark as synced if upload succeeded
          ..latitude = gpsCoordinates?['latitude']
          ..longitude = gpsCoordinates?['longitude'];

        debugPrint('[CheckInService] Check-in object created:');
        debugPrint('[CheckInService]   - photoLocalPath: $savedPath');
        debugPrint('[CheckInService]   - photoUrl: $photoUrl');
        debugPrint('[CheckInService]   - timestamp: ${checkIn.timestamp}');
        debugPrint('[CheckInService]   - isSynced: ${checkIn.isSynced}');
        debugPrint('[CheckInService]   - latitude: ${checkIn.latitude}');
        debugPrint('[CheckInService]   - longitude: ${checkIn.longitude}');
        
        await localDataSource.saveCheckIn(checkIn);
        debugPrint('[CheckInService] ✅ Isar database save SUCCESS - ID: ${checkIn.id}');
      } else {
        if (kIsWeb) {
          debugPrint('[CheckInService] Web platform - skipping Isar save');
        } else {
          debugPrint('[CheckInService] ⚠️ No saved path - skipping Isar save');
        }
      }

      // Mark check-in requirement as fulfilled for this session
      await SharedPreferencesService.markCheckInFulfilled();
      
      debugPrint('[CheckInService] ✅ Check-in process COMPLETED successfully');
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

