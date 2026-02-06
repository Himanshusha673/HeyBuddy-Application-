import 'dart:developer';

import 'package:hey_buddy/features/chat/domain/entities/conversation.dart';
import 'package:hey_buddy/features/chat/domain/entities/message.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.userId,
    required super.username,
    super.userEmail,
    required super.type,
    super.avatarUrl,
    super.unreadCount,
    super.lastMessage,
    super.lastMessageTime,
    super.lastMessageStatus,
    super.createdAt,
    super.updatedAt,
    super.messages = const [],
  });

  factory ConversationModel.fromChatRoom(Map<String, dynamic> json) {
    // Generate a unique ID from the data
    final id = 'conv_${json['userId']}_${json['sender']}';

    // Parse last message if available
    Message? lastMessage;
    if (json['lastMessage'] != null &&
        json['lastMessage'].toString().isNotEmpty) {
      lastMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: json['lastMessage'].toString(),
        senderId: json['sender']?.toString() ?? '',
        receiverId: json['userId']?.toString() ?? '',
        timestamp: DateTime.parse(
          json['lastMessageTime']?.toString() ??
              DateTime.now().toIso8601String(),
        ),
        status: json['lastMessageStatus']?.toString() ?? 'sent',
        role:
            json['sender']?.toString() == json['userId']?.toString()
                ? MessageRole.assistant
                : MessageRole.user,
        isMine: false,
      );
    }

    // Parse dates
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        log('Error parsing createdAt: $e');
        createdAt = DateTime.now();
      }
    }

    DateTime? updatedAt;
    if (json['lastMessageTime'] != null) {
      try {
        updatedAt = DateTime.parse(json['lastMessageTime'].toString());
      } catch (e) {
        log('Error parsing updatedAt: $e');
        updatedAt = DateTime.now();
      }
    }

    return ConversationModel(
      id: id,
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      type: json['chatType']?.toString() ?? 'user',
      avatarUrl: json['avatar']?.toString(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessage: lastMessage,
      lastMessageTime: updatedAt,
      lastMessageStatus: json['lastMessageStatus']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userEmail': userEmail,
      'type': type,
      'avatarUrl': avatarUrl,
      'unreadCount': unreadCount,
      'lastMessage': lastMessage?.content,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageStatus': lastMessageStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
