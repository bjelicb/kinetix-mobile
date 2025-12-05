import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheManager {
  static ImageCacheManager? _instance;
  static ImageCacheManager get instance {
    _instance ??= ImageCacheManager._();
    return _instance!;
  }

  ImageCacheManager._();

  static const String _cacheKey = 'kinetix_image_cache';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _cacheDuration = Duration(days: 30);

  late final CacheManager _cacheManager;

  Future<void> init() async {
    final cacheDir = await getTemporaryDirectory();
    _cacheManager = CacheManager(
      Config(
        _cacheKey,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
  }

  Future<File?> getCachedImage(String imagePath) async {
    try {
      // If it's already a local file path, return it
      if (await File(imagePath).exists()) {
        return File(imagePath);
      }

      // Try to get from cache
      final file = await _cacheManager.getSingleFile(imagePath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('Error getting cached image: $e');
    }
    return null;
  }

  Future<void> cacheImage(String imagePath, Uint8List bytes) async {
    try {
      // Save to cache
      await _cacheManager.putFile(imagePath, bytes);
    } catch (e) {
      print('Error caching image: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cachePath = path.join(cacheDir.path, _cacheKey);
      final dir = Directory(cachePath);
      
      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  Future<void> evictOldCache() async {
    try {
      final cacheSize = await getCacheSize();
      if (cacheSize > _maxCacheSize) {
        // Clear oldest files
        await _cacheManager.emptyCache();
      }
    } catch (e) {
      print('Error evicting cache: $e');
    }
  }
}

