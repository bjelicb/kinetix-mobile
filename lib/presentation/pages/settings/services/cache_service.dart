import '../../../../core/utils/image_cache_manager.dart';

/// Service for cache management operations
class CacheService {
  /// Gets the current cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      return await ImageCacheManager.instance.getCacheSize();
    } catch (e) {
      return 0;
    }
  }

  /// Clears the cache and returns true if successful
  static Future<bool> clearCache() async {
    try {
      await ImageCacheManager.instance.clearCache();
      return true;
    } catch (e) {
      return false;
    }
  }
}

