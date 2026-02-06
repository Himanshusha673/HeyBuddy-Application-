import '../repositories/chat_repository.dart';

class MarkMessagesReadUseCase {
  final ChatRepository repository;

  MarkMessagesReadUseCase(this.repository);

  void call(List<String> messageIds, String senderId, String receiverId) {
    repository.markMessagesAsRead(messageIds, senderId, receiverId);
  }
}
