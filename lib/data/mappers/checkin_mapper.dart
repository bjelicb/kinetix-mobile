import '../../domain/entities/checkin.dart';
import '../models/checkin_collection.dart' if (dart.library.html) '../models/checkin_collection_stub.dart';

class CheckInMapper {
  static CheckIn toEntity(CheckInCollection collection) {
    return CheckIn(
      id: collection.id.toString(),
      photoLocalPath: collection.photoLocalPath,
      photoUrl: collection.photoUrl,
      timestamp: collection.timestamp,
      isSynced: collection.isSynced,
    );
  }
  
  static CheckInCollection toCollection(CheckIn entity, {int? isarId}) {
    final collection = CheckInCollection()
      ..photoLocalPath = entity.photoLocalPath
      ..photoUrl = entity.photoUrl
      ..timestamp = entity.timestamp
      ..isSynced = entity.isSynced;
    
    if (isarId != null) {
      collection.id = isarId;
    }
    
    return collection;
  }
}

