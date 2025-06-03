import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
  });

  // Firestore serialization
  Map<String, dynamic> toJson() => {
        'message': text,
        'isUser': role == MessageRole.user,
        'timestamp': Timestamp.fromDate(timestamp),
        'context': role == MessageRole.bot ? text : null,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json, String id) => ChatMessage(
        id: id,
        text: json['message'] ?? '',
        role: (json['isUser'] ?? false) ? MessageRole.user : MessageRole.bot,
        timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}