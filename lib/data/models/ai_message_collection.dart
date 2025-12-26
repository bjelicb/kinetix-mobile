import 'package:isar/isar.dart';

part 'ai_message_collection.g.dart';

@collection
class AIMessageCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId; // Backend message ID

  late String clientId; // Client user ID
  late String message;
  late String tone; // 'MOTIVATIONAL' | 'WARNING' | 'AGGRESSIVE' | 'EMPATHETIC'
  late bool isRead;
  late DateTime createdAt;
  late DateTime updatedAt;

  AIMessageCollection();

  AIMessageCollection.fromJson(Map<String, dynamic> json)
      : serverId = json['_id']?.toString() ?? json['id']?.toString() ?? '',
        clientId = json['clientId']?.toString() ?? '',
        message = json['message'] as String? ?? '',
        tone = json['tone'] as String? ?? 'MOTIVATIONAL',
        isRead = json['isRead'] as bool? ?? false,
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now();

  Map<String, dynamic> toJson() => {
        'serverId': serverId,
        'clientId': clientId,
        'message': message,
        'tone': tone,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}









