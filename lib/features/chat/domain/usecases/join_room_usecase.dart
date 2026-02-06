import '../repositories/chat_repository.dart';

class JoinRoomUseCase {
  final ChatRepository repository;

  JoinRoomUseCase(this.repository);

  void call(String userId, String partnerId) {
    repository.joinRoom(userId, partnerId);
  }
}