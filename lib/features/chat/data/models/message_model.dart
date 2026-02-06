import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,

    super.chatRoomId,
    required super.content,
    required super.role,
    required super.timestamp,
    super.status,
    super.senderId,
    super.receiverId,
    required super.isMine,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final currentUserId = json['currentUserId']?.toString();
    final isMine = json['isMine'] as bool? ?? 
                  (json['sender']?.toString() == currentUserId);
    
    return MessageModel(
      id: json['_id']?.toString() ?? '',
  
      chatRoomId: json['chatRoomId']?.toString(),
      content: json['message']?.toString() ?? '',
      role: isMine ? MessageRole.user : MessageRole.assistant,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      status: json['status']?.toString(),
      senderId: json['sender']?.toString(),
      receiverId: json['receiver']?.toString(),
      isMine: isMine,
    );
  }

  factory MessageModel.fromSocketData(Map<String, dynamic> data) {
    // Handle both direct message and nested message object
    final messageData = data['message'] is Map ? data['message'] : data;
    final currentUserId = data['currentUserId']?.toString();
    final isMine = messageData['sender']?.toString() == currentUserId;

    return MessageModel(
      id: messageData['messageId']?.toString() ??
          messageData['_id']?.toString() ??
          '',
 
      chatRoomId: messageData['chatRoomId']?.toString(),
      content: messageData['message']?.toString() ?? '',
      role: isMine ? MessageRole.user : MessageRole.assistant,
      timestamp: messageData['timestamp'] != null
          ? DateTime.parse(messageData['timestamp'].toString())
          : messageData['createdAt'] != null
          ? DateTime.parse(messageData['createdAt'].toString())
          : DateTime.now(),
      status: messageData['status']?.toString() ?? 'sent',
      senderId: messageData['sender']?.toString(),
      receiverId: messageData['receiver']?.toString(),
      isMine: isMine,
    );
  }

  // For sending messages
  factory MessageModel.create({
    required String content,
    required String senderId,
    required String receiverId,
    required bool isMine,
    String? chatRoomId,
    String? messageId,
    String status = 'sent',
  }) {
    final now = DateTime.now();
    return MessageModel(
      id: messageId ?? 'msg_${now.millisecondsSinceEpoch}',
      
      chatRoomId: chatRoomId,
      content: content,
      role: isMine ? MessageRole.user : MessageRole.assistant,
      timestamp: now,
      status: status,
      senderId: senderId,
      receiverId: receiverId,
      isMine: isMine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,

      'chatRoomId': chatRoomId,
      'message': content,
      'sender': senderId,
      'receiver': receiverId,
      'status': status,
      'createdAt': timestamp.toIso8601String(),
      'isMine': isMine,
    };
  }

  // For sending to socket
  Map<String, dynamic> toSocketJson() {
    return {
  
      'chatRoomId': chatRoomId,
      'sender': senderId,
      'receiver': receiverId,
      'message': content,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Message toEntity() {
    return Message(
      id: id,

      chatRoomId: chatRoomId,
      content: content,
      role: role,
      timestamp: timestamp,
      status: status,
      senderId: senderId,
      receiverId: receiverId,
      isMine: isMine,
    );
  }
}