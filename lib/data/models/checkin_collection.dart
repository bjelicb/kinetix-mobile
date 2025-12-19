import 'package:isar/isar.dart';

part 'checkin_collection.g.dart';

@collection
class CheckInCollection {
  Id id = Isar.autoIncrement;
  
  late String photoLocalPath;
  String? photoUrl; // Populated after Cloudinary upload
  
  @Index()
  late DateTime timestamp;
  late bool isSynced;
  
  // GPS coordinates
  double? latitude;
  double? longitude;
  
  CheckInCollection();
  
  CheckInCollection.fromJson(Map<String, dynamic> json)
      : photoLocalPath = json['photoLocalPath'] as String,
        photoUrl = json['photoUrl'] as String?,
        timestamp = DateTime.parse(json['timestamp'] as String),
        isSynced = json['isSynced'] as bool? ?? false,
        latitude = (json['latitude'] as num?)?.toDouble(),
        longitude = (json['longitude'] as num?)?.toDouble();
  
  Map<String, dynamic> toJson() => {
        'photoLocalPath': photoLocalPath,
        'photoUrl': photoUrl,
        'timestamp': timestamp.toIso8601String(),
        'isSynced': isSynced,
        'latitude': latitude,
        'longitude': longitude,
      };
}

