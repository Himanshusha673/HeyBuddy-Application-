class AppConstants {
  static const String appName = 'HeyBuddy';
  static const String emulatorUrl = 'http://10.0.2.2:3000/api';
  static const String wsUrlPDevice = 'ws://192.168.0.104:3000';
  static const String wsUrlEmulator = 'ws://10.0.2.2:3000';
  static const String physicalDevice = 'http://192.168.0.104:3000/api';
  static const String wsUrl = wsUrlPDevice;
  static const String baseUrl = physicalDevice;

  static const Duration timeoutDuration = Duration(seconds: 30);
  static const int maxMessageLength = 2000;

  // Offline Storage Keys
  static const String messagesBoxKey = 'offline_messages';
  static const String conversationsBoxKey = 'conversations_cache';
  static const String pendingMessagesBoxKey = 'pending_messages';
}
