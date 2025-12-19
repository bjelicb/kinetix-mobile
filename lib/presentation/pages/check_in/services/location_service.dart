import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for GPS location capture
class LocationService {
  /// Get current GPS location
  /// Returns coordinates or null if unavailable/permission denied
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      debugPrint('[GPS] ═══════════════════════════════════════');
      debugPrint('[GPS] getCurrentLocation() START');

      if (kIsWeb) {
        debugPrint('[GPS] Platform: Web - GPS not available');
        debugPrint('[GPS] ═══════════════════════════════════════');
        return null;
      }

      debugPrint('[GPS] Platform: Mobile (Android/iOS)');

      // Check current permission status BEFORE requesting
      debugPrint('[GPS] Checking current permission status...');
      final currentStatus = await Permission.location.status;
      debugPrint('[GPS] Current permission status: $currentStatus');
      debugPrint('[GPS] Permission details:');
      debugPrint('[GPS]   - isGranted: ${currentStatus.isGranted}');
      debugPrint('[GPS]   - isDenied: ${currentStatus.isDenied}');
      debugPrint('[GPS]   - isPermanentlyDenied: ${currentStatus.isPermanentlyDenied}');
      debugPrint('[GPS]   - isRestricted: ${currentStatus.isRestricted}');
      debugPrint('[GPS]   - isLimited: ${currentStatus.isLimited}');

      // Request permission (will show dialog only if not already granted)
      debugPrint('[GPS] Requesting location permission...');
      final permissionStatus = await Permission.location.request();
      debugPrint('[GPS] Permission request result: $permissionStatus');

      if (permissionStatus.isGranted) {
        debugPrint('[GPS] ✅ Permission GRANTED - Getting position...');
        debugPrint('[GPS] Settings: High accuracy, 10s timeout');

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
        );

        final coordinates = {'latitude': position.latitude, 'longitude': position.longitude};

        debugPrint('[GPS] ✅ Position obtained successfully:');
        debugPrint('[GPS]   - Latitude: ${position.latitude}');
        debugPrint('[GPS]   - Longitude: ${position.longitude}');
        debugPrint('[GPS]   - Accuracy: ${position.accuracy}m');
        debugPrint('[GPS]   - Altitude: ${position.altitude}m');
        debugPrint('[GPS]   - Speed: ${position.speed}m/s');
        debugPrint('[GPS]   - Heading: ${position.heading}°');
        debugPrint('[GPS]   - Timestamp: ${position.timestamp}');
        debugPrint('[GPS] ═══════════════════════════════════════');

        return coordinates;
      } else if (permissionStatus.isDenied) {
        debugPrint('[GPS] ⚠️ Permission DENIED by user');
        debugPrint('[GPS] Check-in will continue without GPS data');
        debugPrint('[GPS] ═══════════════════════════════════════');
        return null;
      } else if (permissionStatus.isPermanentlyDenied) {
        debugPrint('[GPS] ❌ Permission PERMANENTLY DENIED');
        debugPrint('[GPS] User must enable in system settings');
        debugPrint('[GPS] Check-in will continue without GPS data');
        debugPrint('[GPS] ═══════════════════════════════════════');
        return null;
      } else {
        debugPrint('[GPS] ⚠️ Permission status: $permissionStatus');
        debugPrint('[GPS] Check-in will continue without GPS data');
        debugPrint('[GPS] ═══════════════════════════════════════');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[GPS] ❌ ERROR getting location: $e');
      debugPrint('[GPS] Error type: ${e.runtimeType}');
      debugPrint('[GPS] Stack trace: $stackTrace');
      debugPrint('[GPS] Check-in will continue without GPS data');
      debugPrint('[GPS] ═══════════════════════════════════════');
      // Continue without GPS - not blocking
      return null;
    }
  }
}
