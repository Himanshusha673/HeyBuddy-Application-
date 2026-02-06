import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  Future<List<Message>> call(String senderId, String receiverId) async {
    return await repository.getMessages(senderId, receiverId);
  }
}