import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/chat/data/models/conversation_model.dart';
import '../utils/logger.dart';

class OfflineStorage {
  static const String _messagesBox = 'offline_messages';
  static const String _conversationsBox = 'conversations_cache';
  static const String _pendingMessagesBox = 'pending_messages';

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Open boxes
    await Hive.openBox(_messagesBox);
    await Hive.openBox(_conversationsBox);
    await Hive.openBox(_pendingMessagesBox);

    AppLogger.log('Offline storage initialized', 'Storage');
  }

  // ========== Conversations Cache ==========
  Future<void> cacheConversations(List<ConversationModel> conversations) async {
    try {
      final box = Hive.box(_conversationsBox);
      final data = conversations.map((c) => jsonEncode(c.toJson())).toList();
      await box.put('conversations', data);
      AppLogger.log('Cached ${conversations.length} conversations', 'Storage');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache conversations', e, stackTrace);
    }
  }

  Future<List<ConversationModel>?> getCachedConversations() async {
    try {
      final box = Hive.box(_conversationsBox);
      final data = box.get('conversations') as List<dynamic>?;

      if (data == null) return null;

      return data
          .map((item) => ConversationModel.fromChatRoom(jsonDecode(item)))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached conversations', e, stackTrace);
      return null;
    }
  }

  // ========== Messages Cache ==========
  Future<void> cacheMessage(String conversationId, MessageModel message) async {
    try {
      final box = Hive.box(_messagesBox);
      final messages = await _getMessagesForConversation(conversationId);
      messages.add(message);

      await box.put(
        conversationId,
        messages.map((m) => jsonEncode(m.toJson())).toList(),
      );

      AppLogger.log(
        'Cached message for conversation $conversationId',
        'Storage',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache message', e, stackTrace);
    }
  }

  Future<List<MessageModel>> _getMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final box = Hive.box(_messagesBox);
      final data = box.get(conversationId) as List<dynamic>?;

      if (data == null) return [];

      return data
          .map((item) => MessageModel.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ========== Pending Messages (for offline mode) ==========
  Future<void> savePendingMessage(Map<String, dynamic> message) async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final pending = await getPendingMessages();
      pending.add(message);
      await box.put('pending', pending.map((m) => jsonEncode(m)).toList());

      AppLogger.log('Saved pending message', 'Storage');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save pending message', e, stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      final data = box.get('pending') as List<dynamic>?;

      if (data == null) return [];

      return data
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearPendingMessages() async {
    try {
      final box = Hive.box(_pendingMessagesBox);
      await box.delete('pending');
      AppLogger.log('Cleared pending messages', 'Storage');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear pending messages', e, stackTrace);
    }
  }

  Future<void> removePendingMessage(Map<String, dynamic> message) async {
    try {
      final pending = await getPendingMessages();
      pending.removeWhere(
        (m) =>
            m['content'] == message['content'] &&
            m['timestamp'] == message['timestamp'],
      );

      final box = Hive.box(_pendingMessagesBox);
      await box.put('pending', pending.map((m) => jsonEncode(m)).toList());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove pending message', e, stackTrace);
    }
  }

  // ========== Clear All ==========
  Future<void> clearAll() async {
    try {
      await Hive.box(_messagesBox).clear();
      await Hive.box(_conversationsBox).clear();
      await Hive.box(_pendingMessagesBox).clear();
      AppLogger.log('Cleared all offline storage', 'Storage');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear storage', e, stackTrace);
    }
  }
}
