import 'dart:developer';
import 'package:hey_buddy/features/chat/domain/entities/message.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

abstract class ChatRemoteDataSource {
  Future<MessageModel> sendMessage(Message msg, String? recipientId);
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(
    String senderId,
    String receiverId, {
    int page,
    int limit,
  });
  Stream<MessageModel> listenToMessages();
  Stream<Map<String, dynamic>> listenToStatus();
  Stream<Map<String, dynamic>> listenToTyping();
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  void joinRoom(String userId, String partnerId);
  void markMessageAsDelivered(
    String messageId,
    String senderId,
    String receiverId,
  );
  void markMessagesAsRead(
    List<String> messageIds,
    String senderId,
    String receiverId,
  );
  void sendTypingStart(String userId, String receiverId);
  void sendTypingEnd(String userId, String receiverId);
  Future<List<UserModel>> getUsers();
  Future<List<UserModel>> searchUsers(String query);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  final WebSocketClient webSocketClient;
  final SecureStorage secureStorage;
  final Uuid uuid;

  ChatRemoteDataSourceImpl({
    required this.apiClient,
    required this.webSocketClient,
    required this.secureStorage,
  }) : uuid = const Uuid();

  @override
  Future<MessageModel> sendMessage(Message msg, String? recipientId) async {
    if (recipientId == null) {
      throw Exception('Recipient ID is required');
    }

    final userId = await secureStorage.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    webSocketClient.sendMessage(
      messageId: msg.id,
      sender: userId,
      receiver: recipientId,
      message: msg.content,
    );

    return MessageModel(
      id: msg.id,
      content: msg.content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: 'sent',
      senderId: userId,
      receiverId: recipientId,
      isMine: true,
    );
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await apiClient.get(ApiEndpoints.getChatRooms);

    log('Conversations API response: $response');

    if (response['success'] == true && response['data'] != null) {
      final List<dynamic> data = response['data'];

      final List<ConversationModel> conversations = [];

      for (var item in data) {
        try {
          final conversation = ConversationModel.fromChatRoom(item);

          conversations.add(conversation);
        } catch (e, stackTrace) {
          log('Error parsing conversation: $e\n$stackTrace');
          log('Problematic data: $item');
        }
      }

      return conversations;
    }

    log('No conversations data or success false');
    return [];
  }

  @override
  Future<List<MessageModel>> getMessages(
    String senderId,
    String receiverId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.getMessages,
      queryParameters: {
        'senderId': senderId,
        'receiverId': receiverId,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List).map((json) {
        return MessageModel.fromJson(json);
      }).toList();
    }

    return [];
  }

  @override
  Stream<MessageModel> listenToMessages() async* {
    final currentUserId = await secureStorage.getUserId();

    await for (final data in webSocketClient.messageStream) {
      if (data['type'] == 'error' || data['type'] == 'pending') {
        continue;
      }

      log('Processing message: $data');

      if (data['type'] == 'notification') {
        yield MessageModel(
          id: data['messageId'] ?? '',
          content: data['message'] ?? '',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: 'sent',
          senderId: data['senderId']?.toString(),
          receiverId: currentUserId,
          isMine: false,
        );
      } else {
        final messageData = data['message'] is Map ? data['message'] : data;
        final senderId =
            messageData['sender']?.toString() ?? data['sender']?.toString();
        final isMine = senderId == currentUserId;

        yield MessageModel(
          id:
              messageData['messageId']?.toString() ??
              messageData['_id']?.toString() ??
              data['messageId']?.toString() ??
              '',
          content:
              messageData['message']?.toString() ??
              messageData['content']?.toString() ??
              data['message']?.toString() ??
              '',
          role: isMine ? MessageRole.user : MessageRole.assistant,
          timestamp:
              messageData['timestamp'] != null
                  ? DateTime.parse(messageData['timestamp'].toString())
                  : data['timestamp'] != null
                  ? DateTime.parse(data['timestamp'].toString())
                  : DateTime.now(),
          status:
              messageData['status']?.toString() ??
              data['status']?.toString() ??
              'sent',
          senderId: senderId,
          receiverId:
              messageData['receiver']?.toString() ??
              data['receiver']?.toString(),
          isMine: false,
        );
      }
    }
  }

  @override
  Stream<Map<String, dynamic>> listenToStatus() {
    return webSocketClient.statusStream;
  }

  @override
  Stream<Map<String, dynamic>> listenToTyping() {
    return webSocketClient.typingStream;
  }

  @override
  Future<void> connectWebSocket() async {
    await webSocketClient.connect();
  }

  @override
  Future<void> disconnectWebSocket() async {
    await webSocketClient.disconnect();
  }

  @override
  void joinRoom(String userId, String partnerId) {
    webSocketClient.joinRoom(userId, partnerId);
  }

  @override
  void markMessageAsDelivered(
    String messageId,
    String senderId,
    String receiverId,
  ) {
    webSocketClient.markMessageAsDelivered(messageId, senderId, receiverId);
  }

  @override
  void markMessagesAsRead(
    List<String> messageIds,
    String senderId,
    String receiverId,
  ) {
    webSocketClient.markMessagesAsRead(messageIds, senderId, receiverId);
  }

  @override
  void sendTypingStart(String userId, String receiverId) {
    webSocketClient.sendTypingStart(userId, receiverId);
  }

  @override
  void sendTypingEnd(String userId, String receiverId) {
    webSocketClient.sendTypingEnd(userId, receiverId);
  }

  @override
  Future<List<UserModel>> getUsers() async {
    final response = await apiClient.get(ApiEndpoints.getUsers);

    if (response['success'] == true && response['users'] != null) {
      final List list = response['users'];
      return list.map((e) => UserModel.fromJson(e)).toList();
    }

    return [];
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await apiClient.get(
      ApiEndpoints.searchUsers,
      queryParameters: {'query': query},
    );

    if (response['success'] == true && response['users'] != null) {
      final List list = response['users'];
      return list.map((e) => UserModel.fromJson(e)).toList();
    }

    return [];
  }
}
