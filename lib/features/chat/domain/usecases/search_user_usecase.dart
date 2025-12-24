import 'package:hey_buddy/features/chat/domain/entities/user.dart';

import '../../domain/repositories/chat_repository.dart';

class SearchUsersUseCase {
  final ChatRepository repository;

  SearchUsersUseCase(this.repository);

  Future<List<User>> call(String query) {
    return repository.searchHeybuddyUsers(query);
  }
}
