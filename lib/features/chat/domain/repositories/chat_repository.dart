import 'package:hey_buddy/features/chat/domain/entities/user.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage(
    Message msg,


    String? recipientId,
  );
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String senderId, String receiverId);
  Stream<Message> listenToMessages();
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
  Future<List<User>> getAllHeyBuddyUsers();
  Future<List<User>> searchHeybuddyUsers(String query);
}
