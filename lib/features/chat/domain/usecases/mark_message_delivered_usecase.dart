import '../repositories/chat_repository.dart';

class MarkMessageDeliveredUseCase {
  final ChatRepository repository;

  MarkMessageDeliveredUseCase(this.repository);

  void call(String messageId, String senderId, String receiverId) {
    repository.markMessageAsDelivered(messageId, senderId, receiverId);
  }
}
