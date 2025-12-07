import 'package:isar/isar.dart';

part 'user_collection.g.dart';

@collection
class UserCollection {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String serverId; // UUID from backend
  
  late String email;
  late String role; // 'CLIENT' | 'TRAINER' | 'ADMIN'
  late String name;
  String? trainerName; // Assigned trainer for clients
  String? trainerId; // Trainer ID for clients
  bool? isActive; // User active status
  late DateTime lastSync;
  
  UserCollection();
  
  UserCollection.fromJson(Map<String, dynamic> json)
      : serverId = json['serverId'] as String,
        email = json['email'] as String,
        role = json['role'] as String,
        name = json['name'] as String,
        trainerName = json['trainerName'] as String?,
        trainerId = json['trainerId'] as String?,
        isActive = json['isActive'] as bool?,
        lastSync = DateTime.parse(json['lastSync'] as String);
  
  Map<String, dynamic> toJson() => {
        'serverId': serverId,
        'email': email,
        'role': role,
        'name': name,
        'trainerName': trainerName,
        'trainerId': trainerId,
        'isActive': isActive,
        'lastSync': lastSync.toIso8601String(),
      };
}

