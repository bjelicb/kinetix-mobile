import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for GPS location capture
class LocationService {
  /// Get current GPS location
  /// Returns coordinates or null if unavailable/permission denied
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      if (kIsWeb) {
        debugPrint('[CheckIn:GPS] Web platform - GPS not available');
        return null;
      }

      debugPrint('[CheckIn:GPS] Requesting location permission...');
      final permissionStatus = await Permission.location.request();

      if (permissionStatus.isGranted) {
        debugPrint('[CheckIn:GPS] Permission granted, getting location...');
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        final coordinates = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        debugPrint(
          '[CheckIn:GPS] Location obtained: ${coordinates['latitude']}, ${coordinates['longitude']}',
        );
        return coordinates;
      } else {
        debugPrint('[CheckIn:GPS] Location permission denied');
        return null;
      }
    } catch (e) {
      debugPrint('[CheckIn:GPS] Error getting location: $e');
      // Continue without GPS - not blocking
      return null;
    }
  }
}

