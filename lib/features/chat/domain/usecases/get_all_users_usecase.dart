
import 'package:hey_buddy/features/chat/domain/entities/user.dart';

import '../../domain/repositories/chat_repository.dart';

class GetAllUsersUseCase {
  final ChatRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<List<User>> call() {
    return repository.getAllHeyBuddyUsers();
  }
}
