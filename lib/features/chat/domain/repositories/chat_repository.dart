import 'package:hey_buddy/features/chat/domain/entities/user.dart';

import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage(
    String conversationId,
    String content,
    String? recipientId,
  );
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getConversationById(String id);
  Future<void> deleteConversation(String id);
  Stream<Message> listenToMessages();
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  Future<List<User>> getAllHeyBuddyUsers();
  Future<List<User>> searchHeybuddyUsers(String query);
}
