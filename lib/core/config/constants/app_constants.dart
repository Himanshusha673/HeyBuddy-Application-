import 'dart:io';

class AppConstants {
  static const String appName = 'HeyBuddy';

  // ---- BASE URLs ----
  static const String _physicalBaseUrl = 'http://192.168.0.185:3300/api';
  static const String _emulatorBaseUrl = 'http://10.0.2.2:3300/api';

  static const String _physicalWsUrl = 'http://192.168.0.185:3300';
  static const String _emulatorWsUrl = 'http://10.0.2.2:3300';

  // ---- AUTO SELECTED ----
  static String get baseUrl {
    if (Platform.isAndroid) {
      return _isEmulator ? _emulatorBaseUrl : _physicalBaseUrl;
    }
    // iOS / macOS
    return 'http://127.0.0.1:3300/api';
  }

  static String get wsUrl {
    if (Platform.isAndroid) {
      return _isEmulator ? _emulatorWsUrl : _physicalWsUrl;
    }
    return 'ws://127.0.0.1:3300';
  }

  /// 🔥 Emulator detection trick
  static bool get _isEmulator {
    return !Platform.environment.containsKey('ANDROID_STORAGE');
  }

  // ---- CONFIG ----
  static const Duration timeoutDuration = Duration(seconds: 30);
  static const int maxMessageLength = 2000;

  // ---- Offline Storage Keys ----
  static const String messagesBoxKey = 'offline_messages';
  static const String conversationsBoxKey = 'conversations_cache';
  static const String pendingMessagesBoxKey = 'pending_messages';
}
