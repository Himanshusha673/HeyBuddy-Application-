import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class ListenToMessagesUseCase {
  final ChatRepository repository;

  ListenToMessagesUseCase(this.repository);

  Stream<Message> call() {
    return repository.listenToMessages();
  }
}