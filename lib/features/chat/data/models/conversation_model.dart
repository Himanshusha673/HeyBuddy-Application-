import '../../domain/entities/conversation.dart';
import 'message_model.dart';
import 'last_message_model.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.userId,
    required super.participantIds,
    required super.messages,
    required super.lastMessage,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['_id'] ?? json['id'],
      type: json['type'] ?? 'ai',
      title: json['title'] ?? '',
      userId: json['userId']?.toString(),

      participantIds: (json['participants'] as List?)
              ?.map((p) => p is Map ? p['_id'].toString() : p.toString())
              .toList() ??
          const [],

    
      messages: (json['messages'] as List?)
              ?.map((m) => MessageModel.fromJson(m))
              .toList() ??
          const [],

      /// ✅ correct lightweight parsing
      lastMessage: json['lastMessage'] != null
          ? LastMessageModel.fromJson(json['lastMessage'])
          : null,

      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      'userId': userId,
      'participants': participantIds,
      'messages':
          messages.map((m) => (m as MessageModel).toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
