import '../repositories/chat_repository.dart';

class SendTypingUseCase {
  final ChatRepository repository;

  SendTypingUseCase(this.repository);

  void startTyping(String userId, String receiverId) {
    repository.sendTypingStart(userId, receiverId);
  }

  void endTyping(String userId, String receiverId) {
    repository.sendTypingEnd(userId, receiverId);
  }
}