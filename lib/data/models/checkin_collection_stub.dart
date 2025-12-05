// Stub file for web platform - Isar doesn't work on web
class CheckInCollection {
  int id = 0; // Match Isar Id type
  String photoLocalPath = '';
  String? photoUrl;
  DateTime timestamp = DateTime.now();
  bool isSynced = false;
  
  CheckInCollection();
  
  Map<String, dynamic> toJson() => {
        'photoLocalPath': photoLocalPath,
        'photoUrl': photoUrl,
        'timestamp': timestamp.toIso8601String(),
        'isSynced': isSynced,
      };
}

class CheckInCollectionSchema {
  // Stub for web
}
