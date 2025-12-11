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
      // Read image bytes
      Uint8List imageBytes;
      if (!kIsWeb) {
        imageBytes = await io.File(capturedImage.path).readAsBytes();
      } else {
        imageBytes = await capturedImage.readAsBytes();
      }

      // Validate check-in date vs workout date
      final localDataSource = LocalDataSource();
      final todayWorkouts = await localDataSource.getTodayWorkouts();
      final checkInDate = DateTime.now();

      String? validationWarning;
      if (todayWorkouts.isNotEmpty) {
        final workoutDate = todayWorkouts.first.scheduledDate;
        final validation = CheckInValidationService.validateCheckInDate(checkInDate, workoutDate);

        if (!validation.isValid && validation.warningMessage != null) {
          validationWarning = validation.warningMessage;
          debugPrint('[CheckIn] Warning: $validationWarning');
          // Continue with check-in despite warning
        }
      }

      // Compress and resize image
      final compressedBytes = await ImageCompressionService.compressAndResizeImage(imageBytes);

      // Save compressed image locally (skip on web)
      String? savedPath;
      if (!kIsWeb) {
        savedPath = await ImageCompressionService.saveCompressedImageLocally(compressedBytes);
      }

      // Get GPS location
      final gpsCoordinates = await LocationService.getCurrentLocation();

      // Upload to Cloudinary and create check-in
      String? photoUrl;
      try {
        final storage = FlutterSecureStorage();
        final dio = Dio();
        final remoteDataSource = RemoteDataSource(dio, storage);
        final cloudinaryService = CloudinaryUploadService(remoteDataSource);

        // Upload to Cloudinary
        photoUrl = await cloudinaryService.uploadCheckInPhoto(compressedBytes);

        // Create check-in via API
        final checkInData = {
          'checkinDate': DateTime.now().toIso8601String(),
          'photoUrl': photoUrl,
          'gpsCoordinates': gpsCoordinates,
        };

        await remoteDataSource.createCheckIn(checkInData);
      } catch (uploadError) {
        // If upload fails, still save locally for later sync
        debugPrint('Cloudinary upload failed, saving locally for sync: $uploadError');
      }

      // Save to Isar database (skip on web)
      if (!kIsWeb && savedPath != null) {
        final checkIn = CheckInCollection()
          ..photoLocalPath = savedPath
          ..photoUrl = photoUrl
          ..timestamp = DateTime.now()
          ..isSynced = photoUrl != null; // Mark as synced if upload succeeded

        await localDataSource.saveCheckIn(checkIn);
      }

      return CheckInSaveResult(
        success: true,
        warningMessage: validationWarning,
      );
    } catch (e) {
      debugPrint('Error saving check-in: $e');
      return CheckInSaveResult(success: false);
    }
  }
}

