class AIMessage {
  final String id;
  final String message;
  final AIMessageTone tone;
  final DateTime createdAt;
  final bool isRead;

  AIMessage({
    required this.id,
    required this.message,
    required this.tone,
    required this.createdAt,
    required this.isRead,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['_id'] ?? json['id'] ?? '',
      message: json['message'] ?? '',
      tone: _toneFromString(json['tone'] ?? 'MOTIVATIONAL'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  static AIMessageTone _toneFromString(String tone) {
    switch (tone.toUpperCase()) {
      case 'AGGRESSIVE':
        return AIMessageTone.aggressive;
      case 'EMPATHETIC':
        return AIMessageTone.empathetic;
      case 'MOTIVATIONAL':
        return AIMessageTone.motivational;
      case 'WARNING':
        return AIMessageTone.warning;
      default:
        return AIMessageTone.motivational;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'tone': tone.toString().split('.').last.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  AIMessage copyWith({
    String? id,
    String? message,
    AIMessageTone? tone,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AIMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      tone: tone ?? this.tone,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum AIMessageTone {
  aggressive,
  empathetic,
  motivational,
  warning,
}

