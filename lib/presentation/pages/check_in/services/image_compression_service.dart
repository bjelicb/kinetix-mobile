import 'dart:io' as io show Directory, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/utils/image_cache_manager.dart';

/// Service for image compression and local storage
class ImageCompressionService {
  /// Compress and resize image to max 1920x1920 with 85% quality
  static Future<Uint8List> compressAndResizeImage(Uint8List imageBytes) async {
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      debugPrint('[CheckIn:Image] Failed to decode image');
      return imageBytes; // Return original if decode fails
    }

    img.Image imageToCompress;
    
    // Only resize if image is larger than 1920 in any dimension
    if (originalImage.width > 1920 || originalImage.height > 1920) {
      // Resize to max 1920 on the larger dimension while maintaining aspect ratio
      if (originalImage.width >= originalImage.height) {
        imageToCompress = img.copyResize(originalImage, width: 1920);
      } else {
        imageToCompress = img.copyResize(originalImage, height: 1920);
      }
    } else {
      // Image is already small enough, no resize needed
      imageToCompress = originalImage;
    }

    // Compress to JPEG with 85% quality
    return Uint8List.fromList(
      img.encodeJpg(imageToCompress, quality: 85),
    );
  }

  /// Save compressed image to local storage
  /// Returns saved file path or null on failure
  static Future<String?> saveCompressedImageLocally(Uint8List imageBytes) async {
    if (kIsWeb) {
      return null; // Web doesn't save locally
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final checkinsDir = io.Directory(path.join(appDir.path, 'checkins'));
      if (!await checkinsDir.exists()) {
        await checkinsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'checkin_$timestamp.jpg';
      final savedPath = path.join(checkinsDir.path, fileName);
      final savedFile = io.File(savedPath);
      await savedFile.writeAsBytes(imageBytes);

      // Cache the image
      await ImageCacheManager.instance.cacheImage(savedPath, imageBytes);

      return savedPath;
    } catch (e) {
      debugPrint('[CheckIn:Image] Error saving image locally: $e');
      return null;
    }
  }
}

