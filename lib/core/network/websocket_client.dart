import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/constants/app_constants.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';

enum WebSocketStatus { connecting, connected, disconnected, error }

class WebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<dynamic>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  final SecureStorage _secureStorage = SecureStorage();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  WebSocketStatus get currentStatus => _currentStatus;

  Future<void> connect() async {
    if (_currentStatus == WebSocketStatus.connected ||
        _currentStatus == WebSocketStatus.connecting) {
      AppLogger.log('WebSocket already connected or connecting', 'WS');
      return;
    }

    try {
      _updateStatus(WebSocketStatus.connecting);

      final token = await _secureStorage.getToken();
      final wsUrl = AppConstants.wsUrl;

      final uri = Uri.parse('$wsUrl?token=$token');

      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _updateStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;

      AppLogger.log('WebSocket connected successfully', 'WS');

 
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnect,
        cancelOnError: false,
      );


      _startPingTimer();
    } catch (e, stackTrace) {
      AppLogger.error('WebSocket connection failed', e, stackTrace);
      _updateStatus(WebSocketStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      AppLogger.log('WebSocket message received: $data', 'WS');
      _messageController.add(data);
    } catch (e) {
      AppLogger.error(
        'Failed to parse WebSocket message',
        e,
        StackTrace.current,
      );
    }
  }

  void _onError(error) {
    AppLogger.error('WebSocket error', error, StackTrace.current);
    _updateStatus(WebSocketStatus.error);
  }

  void _onDisconnect() {
    AppLogger.log('WebSocket disconnected', 'WS');
    _updateStatus(WebSocketStatus.disconnected);
    _stopPingTimer();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.log('Max reconnect attempts reached', 'WS');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      AppLogger.log('Reconnecting... Attempt $_reconnectAttempts', 'WS');
      connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_currentStatus == WebSocketStatus.connected) {
        send({'type': 'ping'});
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void send(Map<String, dynamic> data) {
    if (_currentStatus != WebSocketStatus.connected) {
      AppLogger.log('Cannot send message: WebSocket not connected', 'WS');
      return;
    }

    try {
      final message = jsonEncode(data);
      _channel?.sink.add(message);
      AppLogger.log('WebSocket message sent: $data', 'WS');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send WebSocket message', e, stackTrace);
    }
  }

  void _updateStatus(WebSocketStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _stopPingTimer();

    await _channel?.sink.close(status.normalClosure);
    _channel = null;

    _updateStatus(WebSocketStatus.disconnected);
    AppLogger.log('WebSocket disconnected manually', 'WS');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
