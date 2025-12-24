import 'package:hey_buddy/features/chat/domain/repositories/chat_repository.dart';

class ConnectWebSocketUseCase {
  final ChatRepository repository;

  ConnectWebSocketUseCase(this.repository);

  Future<void> call() {
    return repository.connectWebSocket();
  }
}
