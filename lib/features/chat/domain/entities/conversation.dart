import 'package:equatable/equatable.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String? userEmail;
  final String type; // 'ai' or 'user'
  final String? avatarUrl;
  final int? unreadCount;
  final Message? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Message> messages;

  const Conversation({
    required this.id,
    required this.userId,
    required this.username,
    this.userEmail,
    required this.type,
    this.avatarUrl,
    this.unreadCount,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageStatus,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    userEmail,
    type,
    avatarUrl,
    unreadCount,
    lastMessage,
    lastMessageTime,
    lastMessageStatus,
    createdAt,
    updatedAt,
    messages,
  ];

  Conversation copyWith({
    String? id,
    String? userId,
    String? username,
    String? userEmail,
    String? type,
    String? avatarUrl,
    int? unreadCount,
    Message? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}