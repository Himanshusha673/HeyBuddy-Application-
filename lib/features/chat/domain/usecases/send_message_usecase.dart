import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Message> call(
    String conversationId,
    String content, {
    String? recipientId, // ADDED THIS
  }) {
    return repository.sendMessage(conversationId, content, recipientId);
  }
}
