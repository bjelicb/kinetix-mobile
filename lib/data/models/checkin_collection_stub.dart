// Stub file for web platform - Isar doesn't work on web
class CheckInCollection {
  int id = 0; // Match Isar Id type
  String photoLocalPath = '';
  String? photoUrl;
  DateTime timestamp = DateTime.now();
  bool isSynced = false;
  
  // GPS coordinates
  double? latitude;
  double? longitude;
  
  CheckInCollection();
  
  Map<String, dynamic> toJson() => {
        'photoLocalPath': photoLocalPath,
        'photoUrl': photoUrl,
        'timestamp': timestamp.toIso8601String(),
        'isSynced': isSynced,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class CheckInCollectionSchema {
  // Stub for web
}
