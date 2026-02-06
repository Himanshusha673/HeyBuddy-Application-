import 'package:hey_buddy/core/network/connectivity_manager.dart';
import 'package:hey_buddy/core/storage/offline_storage.dart';
import 'package:hey_buddy/features/chat/domain/entities/user.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

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
  Future<Message> sendMessage(Message msg, String? recipientId) async {
    if (!connectivityManager.isOnline) {
      await offlineStorage.savePendingMessage({
        'content': msg.content,
        'recipientId': recipientId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      throw Exception(
        'No internet connection. Message will be sent when online.',
      );
    }

    final message = await remoteDataSource.sendMessage(msg, recipientId);

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
      final cached = await offlineStorage.getCachedConversations();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Message>> getMessages(String senderId, String receiverId) async {
    return await remoteDataSource.getMessages(senderId, receiverId);
  }

  @override
  Stream<Message> listenToMessages() {
    return remoteDataSource.listenToMessages();
  }

  @override
  Stream<Map<String, dynamic>> listenToStatus() {
    return remoteDataSource.listenToStatus();
  }

  @override
  Stream<Map<String, dynamic>> listenToTyping() {
    return remoteDataSource.listenToTyping();
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
  void joinRoom(String userId, String partnerId) {
    remoteDataSource.joinRoom(userId, partnerId);
  }

  @override
  void markMessageAsDelivered(
    String messageId,
    String senderId,
    String receiverId,
  ) {
    remoteDataSource.markMessageAsDelivered(messageId, senderId, receiverId);
  }

  @override
  void markMessagesAsRead(
    List<String> messageIds,
    String senderId,
    String receiverId,
  ) {
    remoteDataSource.markMessagesAsRead(messageIds, senderId, receiverId);
  }

  @override
  void sendTypingStart(String userId, String receiverId) {
    remoteDataSource.sendTypingStart(userId, receiverId);
  }

  @override
  void sendTypingEnd(String userId, String receiverId) {
    remoteDataSource.sendTypingEnd(userId, receiverId);
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
