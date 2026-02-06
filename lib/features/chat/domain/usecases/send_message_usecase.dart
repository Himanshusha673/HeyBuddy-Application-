import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Message> call(
    Message msg, {
    String? recipientId, 
  }) {
    return repository.sendMessage(msg, recipientId);
  }
}
