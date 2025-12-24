import 'package:hey_buddy/features/auth/data/models/user_model.dart';
import 'package:hey_buddy/features/chat/data/models/user_model.dart';

import '../../../../core/config/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
    String? recipientId,
  );
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getConversationById(String id);
  Future<void> deleteConversation(String id);
  Stream<MessageModel> listenToMessages();
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  Future<List<UserModel>> getUsers();
  Future<List<UserModel>> searchUsers(String query);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  final WebSocketClient webSocketClient;

  ChatRemoteDataSourceImpl({
    required this.apiClient,
    required this.webSocketClient,
  });

  @override
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
    String? recipientId,
  ) async {
    final body = {'content': content};

    // Only add conversationId if it's not empty
    if (conversationId.isNotEmpty) {
      body['conversationId'] = conversationId;
    }

    // Add recipientId if provided (for user-to-user chat)
    if (recipientId != null) {
      body['recipientId'] = recipientId;
    }

    final response = await apiClient.post(ApiEndpoints.sendMessage, body: body);

    return MessageModel.fromJson(response['message']);
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await apiClient.get(ApiEndpoints.conversations);

    return (response['conversations'] as List)
        .map((json) => ConversationModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<MessageModel>> getConversationById(String id) async {
    final res = await apiClient.get(ApiEndpoints.conversationById(id));
    return (res['conversation']['messages'] as List)
        .map((e) => MessageModel.fromJson(e))
        .toList();
  }

  @override
  Future<void> deleteConversation(String id) async {
    await apiClient.delete(ApiEndpoints.deleteConversation(id));
  }

  @override
  Stream<MessageModel> listenToMessages() {
    return webSocketClient.messageStream
        .where((data) {
          return data['type'] == 'message';
        })
        .map((data) {
          return MessageModel.fromJson(data['message']);
        });
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
  Future<List<UserModel>> getUsers() async {
    final response = await apiClient.get(ApiEndpoints.getUsers);

    final List list = response['users'];
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await apiClient.get(
      ApiEndpoints.searchUsers,
      queryParameters: {'query': query},
    );

    final List list = response['users'];
    return list.map((e) => UserModel.fromJson(e)).toList();
  }
}
