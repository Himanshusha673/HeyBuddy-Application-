import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants/app_constants.dart';
import '../storage/secure_storage.dart';

class WebSocketClient {
  IO.Socket? _socket;
  final SecureStorage _secureStorage;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  bool get isConnected => _socket?.connected ?? false;

  WebSocketClient(this._secureStorage);

  Future<void> connect() async {
    if (_socket?.connected == true) {
      log('✅ WebSocket already connected');
      return;
    }

    try {
      final token = await _secureStorage.getToken();
      final userId = await _secureStorage.getUserId();

      if (token == null || userId == null) {
        throw Exception('Authentication required - no token or userId');
      }

      log('🔄 Connecting to WebSocket: ${AppConstants.wsUrl}');
      log('🔑 UserId: $userId');

      _socket = IO.io(
        AppConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(10)
            .setExtraHeaders({'authorization': 'Bearer $token'})
            .build(),
      );

      _socket!.onConnect((_) {
        log('✅ WebSocket connected successfully');
        // Register user immediately on connection
        _socket!.emit('register_user', {'userId': userId});
        log('📝 User registered with userId: $userId');
      });

      _socket!.on('new_message', (data) {
        log('📨 New message received: $data');
        try {
          if (data is Map<String, dynamic>) {
            _messageController.add(data);
          } else {
            log('⚠️ Invalid message format: $data');
          }
        } catch (e) {
          log('❌ Error processing new message: $e');
        }
      });

      _socket!.on('new_message_notification', (data) {
        log('🔔 New message notification: $data');
        try {
          if (data is Map<String, dynamic>) {
            _messageController.add({'type': 'notification', ...data});
          }
        } catch (e) {
          log('❌ Error processing notification: $e');
        }
      });

      _socket?.on('message_status', (data) {
        log('✓ Message status update: $data');
        try {
          if (data is Map<String, dynamic>) {
            _statusController.add(data);
          }
        } catch (e) {
          log('❌ Error processing status: $e');
        }
      });

      _socket!.on('user_status', (data) {
        log('👤 User status update: $data');
        try {
          if (data is Map<String, dynamic>) {
            _statusController.add({'type': 'user_status', ...data});
          }
        } catch (e) {
          log('❌ Error processing user status: $e');
        }
      });

      _socket!.on('typing_indicator', (data) {
        log('⌨️ Typing indicator: $data');
        try {
          if (data is Map<String, dynamic>) {
            _typingController.add(data);
          }
        } catch (e) {
          log('❌ Error processing typing: $e');
        }
      });

      _socket!.on('pending_messages', (data) {
        log('📬 Pending messages: $data');
        try {
          if (data is Map<String, dynamic>) {
            _messageController.add({'type': 'pending', ...data});
          }
        } catch (e) {
          log('❌ Error processing pending messages: $e');
        }
      });

      _socket!.on('message_error', (data) {
        log('❌ Message error: $data');
        try {
          if (data is Map<String, dynamic>) {
            _messageController.add({'type': 'error', ...data});
          }
        } catch (e) {
          log('❌ Error processing error message: $e');
        }
      });

      _socket!.on('error', (error) {
        log('❌ Socket error event: $error');
      });

      _socket!.onDisconnect((_) {
        log('⚠️ WebSocket disconnected');
      });

      _socket!.onConnectError((error) {
        log('❌ WebSocket connection error: $error');
      });

      _socket!.onReconnect((_) {
        log('🔄 WebSocket reconnected');
        // Re-register user on reconnection
        _socket!.emit('register_user', {'userId': userId});
      });

      _socket!.onReconnectAttempt((attemptNumber) {
        log('🔄 WebSocket reconnection attempt #$attemptNumber');
      });

      _socket!.onReconnectError((error) {
        log('❌ WebSocket reconnection error: $error');
      });

      _socket!.onReconnectFailed((_) {
        log('❌ WebSocket reconnection failed after all attempts');
      });

      _socket!.connect();
      log('🔄 WebSocket connection initiated');
    } catch (e, stackTrace) {
      log('❌ Failed to connect WebSocket: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  void joinRoom(String userId, String partnerId) {
    if (_socket?.connected != true) {
      log('❌ Cannot join room: Socket not connected');
      return;
    }

    try {
      _socket?.emit('join_room', {'userId': userId, 'partnerId': partnerId});
      log('✅ Joined room: $userId - $partnerId');
    } catch (e) {
      log('❌ Error joining room: $e');
    }
  }

  void sendMessage({
    required String messageId,
    required String sender,
    required String receiver,
    required String message,
  }) {
    if (_socket?.connected != true) {
      log('❌ Cannot send message: Socket not connected');
      throw Exception('Socket not connected');
    }

    try {
      final messageData = {
        'message': {
          'messageId': messageId,
          'sender': sender,
          'receiver': receiver,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      _socket!.emit('send_message', messageData);
      log('✅ Message sent via socket: $messageId');
    } catch (e) {
      log('❌ Error sending message: $e');
      rethrow;
    }
  }

  void markMessageAsDelivered(
    String messageId,
    String senderId,
    String receiverId,
  ) {
    if (_socket?.connected != true) {
      log('⚠️ Cannot mark message delivered: Socket not connected');
      return;
    }

    try {
      _socket!.emit('message_delivered', {
        'messageId': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
      });
    } catch (e) {
      log('❌ Error marking message delivered: $e');
    }
  }

  void markMessagesAsRead(
    List<String> messageIds,
    String senderId,
    String receiverId,
  ) {
    if (_socket?.connected != true) {
      log('⚠️ Cannot mark messages read: Socket not connected');
      return;
    }

    try {
      _socket!.emit('message_read', {
        'messageIds': messageIds,
        'senderId': senderId,
        'receiverId': receiverId,
      });
    } catch (e) {
      log('❌ Error marking messages read: $e');
    }
  }

  void markAllMessagesAsRead(String userId, String partnerId) {
    if (_socket?.connected != true) {
      log('⚠️ Cannot mark all messages read: Socket not connected');
      return;
    }

    try {
      _socket!.emit('mark_messages_read', {
        'userId': userId,
        'partnerId': partnerId,
      });
    } catch (e) {
      log('❌ Error marking all messages read: $e');
    }
  }

  void sendTypingStart(String userId, String receiverId) {
    if (_socket?.connected != true) return;

    try {
      _socket!.emit('typing_start', {
        'userId': userId,
        'receiverId': receiverId,
      });
    } catch (e) {
      log('❌ Error sending typing start: $e');
    }
  }

  void sendTypingEnd(String userId, String receiverId) {
    if (_socket?.connected != true) return;

    try {
      _socket!.emit('typing_end', {'userId': userId, 'receiverId': receiverId});
    } catch (e) {
      log('❌ Error sending typing end: $e');
    }
  }

  void updateUserStatus(String userId, String status, {String? lastSeen}) {
    if (_socket?.connected != true) return;

    try {
      _socket!.emit('user_status_change', {
        'userId': userId,
        'status': status,
        if (lastSeen != null) 'lastSeen': lastSeen,
      });
    } catch (e) {
      log('❌ Error updating user status: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      log('✅ WebSocket disconnected and disposed');
    } catch (e) {
      log('❌ Error disconnecting WebSocket: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _statusController.close();
    _typingController.close();
    disconnect();
  }
}
