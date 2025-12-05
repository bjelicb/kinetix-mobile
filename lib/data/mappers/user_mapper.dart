import '../../domain/entities/user.dart';
import '../models/user_collection.dart' if (dart.library.html) '../models/user_collection_stub.dart';

class UserMapper {
  static User toEntity(UserCollection collection) {
    return User(
      id: collection.serverId,
      email: collection.email,
      role: collection.role,
      name: collection.name,
      lastSync: collection.lastSync,
    );
  }
  
  static UserCollection toCollection(User entity, {int? isarId}) {
    final collection = UserCollection()
      ..serverId = entity.id
      ..email = entity.email
      ..role = entity.role
      ..name = entity.name
      ..lastSync = entity.lastSync;
    
    if (isarId != null) {
      collection.id = isarId;
    }
    
    return collection;
  }
}

