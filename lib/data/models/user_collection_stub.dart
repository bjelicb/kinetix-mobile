// Stub file for web platform - Isar doesn't work on web
class UserCollection {
  int id = 0; // Match Isar Id type
  String serverId = '';
  String email = '';
  String role = '';
  String name = '';
  DateTime lastSync = DateTime.now();
  
  UserCollection();
  
  UserCollection.fromJson(Map<String, dynamic> json)
      : serverId = json['serverId'] as String,
        email = json['email'] as String,
        role = json['role'] as String,
        name = json['name'] as String,
        lastSync = DateTime.parse(json['lastSync'] as String);
  
  Map<String, dynamic> toJson() => {
        'serverId': serverId,
        'email': email,
        'role': role,
        'name': name,
        'lastSync': lastSync.toIso8601String(),
      };
}

class UserCollectionSchema {
  // Stub for web
}
