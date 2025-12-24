import 'package:hey_buddy/core/network/connectivity_manager.dart';
import 'package:hey_buddy/core/storage/offline_storage.dart';

import 'package:hey_buddy/features/chat/domain/entities/user.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final OfflineStorage offlineStorage;
  final ConnectivityManager connectivityManager;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineStorage,
    required this.connectivityManager,
  });

  @override
  Future<Message> sendMessage(String conversationId, String content, String? recipientId,) async {
   if (!connectivityManager.isOnline) {
      await offlineStorage.savePendingMessage({
        'conversationId': conversationId,
        'content': content,
        'recipientId': recipientId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final tempMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      if (conversationId.isNotEmpty) {
        await offlineStorage.cacheMessage(conversationId, tempMessage);
      }

      return tempMessage;
    }

    final message = await remoteDataSource.sendMessage(
      conversationId,
      content,
   recipientId,
    );

    if (conversationId.isNotEmpty) {
      await offlineStorage.cacheMessage(conversationId, message);
    }

    return message;
  }

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      if (!connectivityManager.isOnline) {
        final cached = await offlineStorage.getCachedConversations();
        if (cached != null) return cached;
        throw Exception('No cached data available');
      }

      final conversations = await remoteDataSource.getConversations();
      await offlineStorage.cacheConversations(conversations);
      return conversations;
    } catch (e) {
      // Try to return cached data on error
      final cached = await offlineStorage.getCachedConversations();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Message>> getConversationById(String id) async {
    return await remoteDataSource.getConversationById(id);
  }

  @override
  Future<void> deleteConversation(String id) async {
    await remoteDataSource.deleteConversation(id);
  }

  @override
  Stream<Message> listenToMessages() {
    return remoteDataSource.listenToMessages();
  }

  @override
  Future<void> connectWebSocket() async {
    await remoteDataSource.connectWebSocket();
  }

  @override
  Future<void> disconnectWebSocket() async {
    await remoteDataSource.disconnectWebSocket();
  }

  @override
  Future<List<User>> getAllHeyBuddyUsers() async {
    return await remoteDataSource.getUsers();
  }

  @override
  Future<List<User>> searchHeybuddyUsers(String query) async {
    return await remoteDataSource.searchUsers(query);
  }
}
