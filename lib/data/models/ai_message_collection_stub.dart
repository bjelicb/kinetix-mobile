// Stub version for web platform (Isar not available)
class AIMessageCollection {
  int id = 0;
  String serverId = '';
  String clientId = '';
  String message = '';
  String tone = 'MOTIVATIONAL';
  bool isRead = false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

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

// Stub schema for web platform (Isar not available)
class AIMessageCollectionSchema {
  const AIMessageCollectionSchema();
}

