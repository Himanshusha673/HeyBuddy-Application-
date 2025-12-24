import 'dart:developer' as developer;

class AppLogger {
  static void log(String message, [String name = 'APP']) {
    developer.log(message, name: name);
  }

  static void error(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message) {
    developer.log(message, name: 'INFO');
  }

  static void warning(String message) {
    developer.log(message, name: 'WARNING');
  }
}