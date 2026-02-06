import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class ListenToMessagesUseCase {
  final ChatRepository repository;

  ListenToMessagesUseCase(this.repository);

  Stream<Message> call() {
    return repository.listenToMessages();
  }

  Stream<Map<String, dynamic>> statusStream() {
    return repository.listenToStatus();
  }

  Stream<Map<String, dynamic>> typingStream() {
    return repository.listenToTyping();
  }
}