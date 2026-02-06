// class ApiEndpoints {
//   // Auth
//   static const String login = '/auth/login';
//   static const String register = '/auth/register';
//   static const String logout = '/auth/logout';
//   static const String refreshToken = '/auth/refresh';
//   static const String currentUser = '/auth/me';

//   // Chat
//   static const String sendMessage = '/chat/send';
//   static const String conversations = '/chat/conversations';
//   static String conversationById(String id) => '/chat/conversations/$id';
//   static String deleteConversation(String id) => '/chat/conversations/$id';
//   static const String streamResponse = '/chat/stream';
//   static const String getUsers = '/chat/users';
//   static const String searchUsers = '/chat/users/search';
// }

class ApiEndpoints {
  // Auth
  static const String login = '/users/login';
  static const String register = '/users/register';

  // Chat
  static const String getMessages = '/chat/messages';
  static const String getChatRooms = '/chat/chat-rooms';
  static const String getUsers = '/chat/users';
  static const String searchUsers = '/chat/users/search';
}
