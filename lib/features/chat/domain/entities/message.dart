import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class Message extends Equatable {
  final String id;            // Mongo _id
   // msg_xxx (optional)
  final String? chatRoomId;   // room ID (optional)
  final String content;       // message
  final MessageRole role;     // derived from isMine
  final DateTime timestamp;   // createdAt
  final String? status;       // sent / delivered / read
  final String? senderId;
  final String? receiverId;
  final bool isMine;

  const Message({
    required this.id,
   
    this.chatRoomId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status,
    this.senderId,
    this.receiverId,
    required this.isMine,
  });

  bool get isUser => role == MessageRole.user;
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';

  Message copyWith({
    String? id,
    String? messageId,
    String? chatRoomId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    String? status,
    String? senderId,
    String? receiverId,
    bool? isMine,
  }) {
    return Message(
      id: id ?? this.id,
 
      chatRoomId: chatRoomId ?? this.chatRoomId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      isMine: isMine ?? this.isMine,
    );
  }

  @override
  List<Object?> get props => [
        id,
      
        chatRoomId,
        content,
        role,
        timestamp,
        status,
        senderId,
        receiverId,
        isMine,
      ];
}